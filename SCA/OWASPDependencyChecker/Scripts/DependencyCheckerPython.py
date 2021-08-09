#Basic Python Script to teach myself Python.
#Converted a script I already had from Powershell to Python
#This Script runs OWASP DependencyChecker on a code base and outputs the results

class DependencyCheck:

    #imports
    import os
    #Variables

    projectId = "ProjectName"
    locationToScan = ""
    #File path to supression file, this is not always needed to run Dependency Check
    supressionFile = ""
    outputLocation = ""
    exclusionsList = ""
    dependencyCheckLocation = "C:/Users/JamesSunley/Documents/dependency-check-6.2.2-release/dependency-check/bin/dependency-check.bat"

    #Set variables
    projectId = input("Enter project ID: ")
    locationToScan = input("Specify the location to scan: ")
    supressionFile = input("Set the suppression file: ")
    outputLocation = input("Set the output location: ")
        
    #Sets a list of folders and files to exclude
    def Exclusions():
        exclusions = "\Tests\**"
        return exclusions

    def Scan(locationToScan, supressionFile, outputLocation, exclusionsList, dependencyCheckLocation, projectId, os):
            print("Starting Scan")
            print("Folder to scan: " + locationToScan)
            print("Report will be output to: " + outputLocation)
            stream = os.popen(dependencyCheckLocation + ' --project ' + projectId + ' --scan ' + locationToScan + ' --suppression ' + supressionFile + ' --exclude ' + exclusionsList + ' --out ' + outputLocation + ' -f HTML')
            output = stream.read()
            print(output)

    exclusionsList = Exclusions()
    Scan(locationToScan, supressionFile, outputLocation, exclusionsList, dependencyCheckLocation, projectId, os)