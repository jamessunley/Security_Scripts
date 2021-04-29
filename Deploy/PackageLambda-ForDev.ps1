########Create lamda package############
function CreatePackage
([string]$PATH)
{

    cd $PATH

    #dotnet tool install -g Amazon.Lambda.Tools #This command needs to execute for the first time only. Disable it if #
    dotnet lambda package

    $PATH = $PATH + "\bin\Release\netcoreapp3.1"

	cd $CURRENTPATH

    start $PATH
}

########Create and deploy lamda package############
function CreateAndDeployPackage
([string]$PATH)
{

    cd $PATH

    #Create and deploy lamda package
    dotnet lambda deploy-function

	cd $CURRENTPATH
}

########################################################################################
# Main
########################################################################################


##### Set Base path ###

	$CURRENTPATH = Get-Location
    $BASEPATH = $CURRENTPATH | Split-Path 
    Write-Host "@@@Debug BasePath:  $BASEPATH"

############ Select Environment Options:
        [Environment]::NewLine
		$ENV1 = Read-Host "Please enter aws environment dev01/dev02/dev03/dev04/dev05/dev06/dev07?"
		$ENV1 = $ENV1.ToLower();

##### Set lamda path ###
		$APIPATH = $BASEPATH + "\" + "BasePath / src for project"
		$DEMOCLIENTPATH = $BASEPATH + "\" + "Sage.Payments.Out.DemoClient"
		$MESSAGEHANDLERPATH = $BASEPATH + "\" + "Sage.Payments.Out.MessageHandler"
		$MESSAGINGPATH = $BASEPATH + "\" + "Sage.Payments.Out.Messaging"
		$STEPFUNCTIONPATH = $BASEPATH + "\" + "Sage.PC.Plugin.File"
		$POSTDEPLOYMENTPATH = $BASEPATH + "\" + "Sage.Payments.Out.PostDeployment"
		$NOTIFYWEBHOOKPATH = $BASEPATH + "\" + "Sage.Payments.Out.NotifyWebhook"

############ Select Lambda: 
        [Environment]::NewLine
		$LambdaPath = $APIPATH

		Write-host "Please select Lambda project: (1/2/3/4/5/6)"  -ForegroundColor Yellow 
		Write-host "1. Proj1 (Description)" -ForegroundColor Yellow 
		Write-host "2. Proj2 (Description)" -ForegroundColor Yellow 
		Write-host "3. Proj3 (Description)" -ForegroundColor Yellow 
		Write-host "4. Proj4 (Description)" -ForegroundColor Yellow 
		Write-host "5. Proj5 (Description)" -ForegroundColor Yellow 
		Write-host "6. Proj6 (Description)" -ForegroundColor Yellow
		Write-host "7. Proj7 (Description)" -ForegroundColor Yellow
		
		$Readhost2 = Read-Host "(1/2/3/4/5/6/7)" 

		[Environment]::NewLine
		Switch ($Readhost2) 
        { 
           1{
				Write-host "Proj1 selected"-ForegroundColor green;
				Write-host "AWS Lambda Function Name:";
				Write-host "name-$ENV1-eu-west-1-Proj1" -ForegroundColor Yellow ;
				Write-host "name-$ENV1-eu-west-1-Proj1Varient2" -ForegroundColor Yellow ;
				$PublishSettings=$true;
				$LambdaPath = $APIPATH;
			} 
           2{
				Write-Host "Proj2 selected"-ForegroundColor green ; 
				Write-host "AWS Lambda Function Name:";
				Write-host "name-$ENV1-eu-west-1-Proj2"-ForegroundColor Yellow ;
				$PublishSettings=$true;
				$LambdaPath = $DEMOCLIENTPATH;
			}  
           3{
				Write-Host "Proj3 selected"-ForegroundColor green ; 
				Write-host "AWS Lambda Function Name:";
				Write-host "name-$ENV1-eu-west-1-Proj3"-ForegroundColor Yellow ;
				Write-host "name-$ENV1-eu-west-1-Proj3Varient2"-ForegroundColor Yellow ;
				$PublishSettings=$true;
				$LambdaPath = $MESSAGEHANDLERPATH;
			}  
		   4{
				Write-Host "Proj4 selected"-ForegroundColor green ;  
				Write-host "AWS Lambda Function Name:";
				Write-host "name-$ENV1-eu-west-1-Proj4"-ForegroundColor Yellow ;
				Write-host "name-$ENV1-eu-west-1-Proj4Varient2"-ForegroundColor Yellow ;
				Write-host "name-$ENV1-eu-west-1-Proj4Varient3"-ForegroundColor Yellow ;
				$PublishSettings=$true;
				$LambdaPath = $MESSAGINGPATH;
			}  
		   5{
				Write-Host "Proj5 selected"-ForegroundColor green ;  
				Write-host "AWS Lambda Function Name:";
				Write-host  "name-$ENV1-eu-west-1-Proj5"-ForegroundColor Yellow ;
				Write-host  "name-$ENV1-eu-west-1-Proj5Varient2"-ForegroundColor Yellow ;
				Write-host  "name-$ENV1-eu-west-1-Proj5Varient3"-ForegroundColor Yellow ;
				$PublishSettings=$true;
				$LambdaPath = $STEPFUNCTIONPATH;
			}  
		   6{
				Write-Host "Proj6 selected"-ForegroundColor green ; 
				Write-host "AWS Lambda Function Name:";
				Write-host "name-$ENV1-eu-west-1-Proj6"-ForegroundColor Yellow ;
				$PublishSettings=$true;
				$LambdaPath = $POSTDEPLOYMENTPATH;
			}
			7{
				Write-Host "Proj7 selected"-ForegroundColor green ; 
				Write-host "AWS Lambda Function Name:";
				Write-host "name-$ENV1-eu-west-1-Proj7"-ForegroundColor Yellow ;
				$PublishSettings=$true;
				$LambdaPath = $NOTIFYWEBHOOKPATH;
			}  
        } 

############ Select Package Options
        [Environment]::NewLine
		Write-host "Please select your choice: (1/2)"  -ForegroundColor Yellow 
		Write-host "1. Create Lambda Package Only (You need to manually upload package zip in to AWS Lambda)" -ForegroundColor Yellow 
		Write-host "2. Create and Deploy Lambda package (need to supply .net run time (dotnetcore3.1) & lambda function name (can be copied from above))" -ForegroundColor Yellow 
		$Readhost1 = Read-Host " ( 1 / 2 ) " 

		Switch ($Readhost1) 
         { 
           1 {Write-host "Creating Lambda Package"; $PublishSettings=$true; CreatePackage($LambdaPath)} 
           2 {Write-Host "Creating and deploying Lambda package"; $PublishSettings=$false; CreateAndDeployPackage($LambdaPath) } 
         } 
