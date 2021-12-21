#Script to automate getting reports from Checkmarx and posting to the relevent teams channels.
#Config file default location to be saved is - 
#For windows, it should be like C:\\Users\\<UserName>\\.Checkmarx\\config.ini
#For linux and MacOS, it should be like /home/<UserName>/.Checkmarx/config.ini

#imports
from CheckmarxPythonSDK.CxRestAPISDK import ProjectsAPI, ScansAPI
from CheckmarxPythonSDK.CxPortalSoapApiSDK import create_scan_report
from CheckmarxPythonSDK.CxRestAPISDK import AccessControlAPI
from datetime import datetime
from datetime import timedelta
from os.path import exists, join, normpath
import time
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication
from email.mime.text import MIMEText
from os.path import basename
import os
import shutil
import re
import logging

#Variables
#ScanId - the ID of the scan in checkmarx
scanId = ""
#Result states to use in report can be any of the following ["To Verify", "Not Exploitable", "Confirmed", "Urgent", "Proposed Not Exploitable"]
#Currently not using "Non Exploitable"
resultStateForReports = ["To Verify", "Confirmed", "Urgent", "Proposed Not Exploitable"]
#TODO change type to be configurable
reportType = "CSV"
#Api's to be used
ac = AccessControlAPI()
pa = ProjectsAPI()
sa = ScansAPI()
#List of Dictionary of teams
teamList = []
#Folder to output report to
outputFolder = "./reports"
#Dictionary of all projects with team details
projectDictionaryList=[]
#Number of days in past to look for a scan. Should be 30 or 7?
scanRange = 1

#defineloggingparameters
logging.basicConfig(filename='CheckmarxAutomation.log', filemode='w', format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', datefmt='%d-%b-%y . %H:%M:%S', level=logging.INFO)

#Email List 
#TODO add all teams emails
emailList = [""]

logging.info("New Log Entry")

#Returns last scanId based on team full name and project name
#Uses Checkmarx SDK
def GetScansForProject(project_Id):

    print("Project Id = " + str(project_Id))

    scanId = sa.get_last_scan_id_of_a_project(project_id=project_Id, only_finished_scans=True)

    print("Scan Id = " + str(scanId))
    return scanId

#Returns last scanId based on team full name and project name
#But only returns the Id within the last 30 days
def GetScansForProjectInLastMonth(project_Id):

    print("Project Id = " + str(project_Id))

    scanId = sa.get_last_scan_id_of_a_project(project_id=project_Id, only_finished_scans=True)
    if scanId == None:
        return scanId

    #Uses regex to get year date and month
    #This is then used to see if scan was in last 30 days
    scanDetails = sa.get_sast_scan_details_by_scan_id(scanId)
    print(scanDetails.date_and_time.finished_on)
    regexDate = re.findall("^\d{4}\-\d{2}-\d{2}", scanDetails.date_and_time.finished_on)
    print("regex date " + regexDate[0])    

    past = datetime.now() - timedelta(days=scanRange)
    print (past)
    dateOfScan = datetime.strptime(regexDate[0], '%Y-%m-%d')
    print (dateOfScan)
    if past < dateOfScan :
        print("Scan Id = " + str(scanId))
        print("Is within the last 30 days so will be reported on.")
        return scanId


#Verifies result states are valid
def GetResultStateIdList(result_state_list):
    all_result_state_list = ["To Verify", "Not Exploitable", "Confirmed", "Urgent", "Proposed Not Exploitable"]
    result_state_id_list = list()
    for result_state in result_state_list:
        try:
            result_state_id = all_result_state_list.index(result_state)
            result_state_id_list.append(result_state_id)
        except ValueError:
            print("result state: {} Not found".format(result_state))
    return result_state_id_list

#Generates reports based on projectId and scanId
#Outputs report to folder in format based on reportType(e.g. CSV, PDF, XML)
#Result State specifies the state of the vulnerability within Checkmarx. List can include 
#["To Verify", "Not Exploitable", "Confirmed", "Urgent", "Proposed Not Exploitable"]
def GenerateReport(project_name, scan_id, result_state_list, report_type, reports_folder, team_full_name, teamName):

    if not exists(normpath(reports_folder)):
        print("The folder to store the Checkmarx scan reports does not exist")
        return

    if not scan_id:
        print("No scan found for this project, team full name: {}, project name: {}".format(team_full_name, project_name))
        return

    # register scan report
    report = create_scan_report(
        scan_id=scan_id,
        report_type=report_type,
        results_per_vulnerability_maximum=500,
        results_state_all=False,
        results_state_ids=GetResultStateIdList(result_state_list)
    )
    report_id = report["ID"]

    # get report status by id
    while not sa.is_report_generation_finished(report_id):
        time.sleep(10)

    # get report by id
    report_content = sa.get_report_by_id(report_id)

    # write report content into a file 
    #Use dates from when scan was completed rather than current date time??
    time_stamp = datetime.now().strftime('_%Y_%m_%d_%H_%M_%S')
    name = project_name + time_stamp + "." + report_type
    file_name = normpath(join(reports_folder + "/" + teamName, name))

    try:
        with open(str(file_name), "wb") as f_out:
            f_out.write(report_content)
    except: 
        print("An error occured when opening the file ")

#Get all details for all teams, team ID and team full name
def getAllTeams():
    all_teams = ac.get_all_teams()
    for team in all_teams:
        teamList.append({"teamId": team.id, "teamName": team.full_name, "teamNameShort": team.name})

#Get all of the projects details
def getProjectsForTeam(teamList):
    projectList = pa.get_all_project_details()

    #Filter through each project and then each team to add all team details and project details to project dictionary
    for project in projectList:
        #print(project.name)
        teamName = ""
        teamNameShort = ""
        for d in teamList:
            if d['teamId'] == project.team_id:
                teamName = d['teamName']
                teamNameShort = d['teamNameShort']
        #Update project dictionary
        projectDictionaryList.append({"teamId": project.team_id, "projectName": project.name, "projectId": project.project_id, "teamName": teamName, "teamNameShort": teamNameShort})

#Sends email containing zipped reports to security teams + teams channels
def sendemail(emailto, bodyText, teamName):
    #The email that teh reports are sent from
    emailfrom = "Email@email.com" #TODO add email

    #File to be attached - already been zipped
    files = [outputFolder + "/" + teamName+".zip"]

    #Add details to the email
    print("start email")
    msg = MIMEMultipart()
    msg["From"] = emailfrom
    msg["To"] = ",".join(emailto)
    msg["Subject"] = "Monthly Checkmarx scan"
    msg.preamble = "Monthly Checkmarx scan"
    body = bodyText
    msg.attach(MIMEText(body, 'plain'))
    print(files)

    for f in files:
        print(f)
        #Check if file exists before trying to open
        if os.path.isfile(f):
            with open(f, "rb") as fil:
                part = MIMEApplication(
                    fil.read(),
                    Name=basename(f)
            )
            # After the file is closed
            print("attaching file")
            part['Content-Disposition'] = 'attachment; filename="%s"' % basename(f)
            #print(part)
            msg.attach(part)
            
    print("send email")
    #print(msg.as_string)

    server = smtplib.SMTP("")#TODO add server
    server.set_debuglevel(0)
    server.sendmail(emailfrom, emailto, msg.as_string())
    server.quit()

#Zips the file based on the the teamName 
def Zipthefile(teamName):
    print("Zipping folder : " + teamName)
    #TODO add logging
    #logging.info("Zipping the File")
    #Zipped folder is added within reports folder to aid with clean up
    shutil.make_archive(outputFolder + "/" + teamName, 'zip', outputFolder + "/" + teamName)

    #Use the below for zipping individual files rather than folders
    #checkmarx_zip = zipfile.ZipFile(teamName +'.zip', 'w')
    #checkmarx_zip.write(teamName, compress_type=zipfile.ZIP_DEFLATED)

    #checkmarx_zip.close()

#Creates set of directories for each team
#This makes clean up easier
#And allows us to send less emails / messages to the teams channels and mail lists
def CreateFolder():
    #Check if folder exists if yes call CleanUp
    if os.path.isdir(outputFolder):
        CleanUp(outputFolder)

        # Recreate the high level directory after the clean up so folder exists for nested folder creation
        #In the same folder as we are currently in based on the file path recieved
        try: 
            os.mkdir(outputFolder) 
        except OSError as error: 
            print(error)
    else:
        # Create the directory
        #In the same folder as we are currently in based on the file path recieved
        try: 
            os.mkdir(outputFolder) 
        except OSError as error: 
            print(error)

    #Create folder for each project within reports folder
    for team in teamList:
        try:
            os.mkdir(outputFolder + "/" + team['teamNameShort'])
        except OSError as error:
            print(error)

#Clean up method to remove folders and reports once they have been sent to teams channels
def CleanUp(path):
    # Check whether the specified path is an existing directory or not 
    if os.path.isdir(path):
        #Removes folder and all of its contents
        shutil.rmtree(path)
        return


#Run reports and get scans
def RunReports(projectName, teamFullName, resultStateForReports, reportType, outputFolder, projectId, teamName):
    #Get ScanId for report if report is of any age
    #This is commented out
    #Do not use on normal run of script
    #scanId = GetScansForProject(project_Id = projectId)

    #Get ScanId if scan was carried out within the last 30 days
    #This should be used on the normal run of the script
    scanId = GetScansForProjectInLastMonth(project_Id = projectId)

    #Generate and output report
    GenerateReport(
            project_name = projectName,
            scan_id = scanId,
            result_state_list = resultStateForReports,
            report_type = reportType,
            reports_folder = outputFolder,
            team_full_name = teamFullName,
            teamName = teamName
        )

#Runs the sending of the reports and zipping of the folders. This reduces the number of emails sent.
#This should be run at the end of the script to ensure all project reports are added to the relevent teams.
def RunSend(teamName):
    #Normalise Team Name
    #Remove trailing spaces
    teamName = teamName.rstrip()
    print(teamName)
    #Call zip the file
    Zipthefile(teamName)

    # emailto = ["TO-EMAIL1@DOMAIN.COM", "TO-EMAIL2@DOMAIN.COM"] - format if you want to send to multiple email address
    emailto = [""]
    bodyText = "Please see the attached Checkmarx report for team " + teamName + ".\n\
    "
    print(teamName)
    for e in emailList:
        if e.__contains__(teamName):
            print("Contains " + teamName)
            #TODO fix this
            bodyText = bodyText + "This report has been uploaded to the relevent Teams channel"
            #Append email address here for the teams channel

            emailto.append(e)
        else:
            #TODO add logging
            print("Teams email not found for " + teamName)
            bodyText = bodyText + "This email was only sent to security teams as no MS Teams email was found for " + teamName + ".\n\
            Please upload manually to the MS Teams channel."
    if emailto:
        #Call to send email with zipped report
        sendemail(emailto, bodyText, teamName)
    else:
        print ("No emails in list - so no reports sent")

#Call to get all teams details
getAllTeams()

#Call to create directory to store reports
CreateFolder()

#Call to get all project details
getProjectsForTeam(teamList)

#Call run method for each project
#print(projectDictionaryList)
print(len(projectDictionaryList))
for project in projectDictionaryList:
    RunReports(project['projectName'], project['teamName'], resultStateForReports, reportType, outputFolder, project['projectId'], project['teamNameShort'])

#Zip folders and send emails for each product
for team in teamList:
    RunSend(team['teamNameShort'])

#Call Clean up to remove all folders and files after scipt has ran
CleanUp(outputFolder)
