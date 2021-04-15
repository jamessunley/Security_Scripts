#Identify the working folder
$workingFolder = Split-Path -parent $MyInvocation.MyCommand.Definition | Split-Path -parent | Split-Path -parent | Split-Path -parent | Split-Path -parent | Split-Path -parent

Write-Output $workingFolder

$BUILD_ID = "v3"
$SOLUTION = "$workingFolder\src"

#Exclusions - Files and Folders to ignore when scanning
$EX = "-exclude `"$workingFolder\src\Folder.Integration.Tests`""
$EX = " $EX -exclude `"$workingFolder\src\OtherProject.Tests`""
$EX = " $EX -exclude `"$workingFolder\src\FolderName.Tests`""

#Inclusions - Files/Folders to scan - not always needed
$INCLUDE = "-libdirs $workingFolder\src\ProjectName\bin\Debug\netcoreapp2.1"
$INCLUDE = "$INCLUDE $workingFolder\src\ProjectName\bin\Debug\netcoreapp2.1"

#clean build ID
iex "sourceanalyzer.exe -b $BUILD_ID -clean"

"Clean complete"

#Build projects and exclude unwanted files
iex "sourceanalyzer.exe -b $BUILD_ID $EX $SOLUTION"

"Project has been built"
#Scan build
iex "sourceanalyzer.exe -b $BUILD_ID -scan -f fortify-report.fpr"

"Scan Complete"

#Upload to ThreadFix

"Uploading to Threadfix"

iex "java -jar $workingFolder\src\Testing\Security\ThreadFix\tfcli.jar --set key APIKEY"
iex "java -jar $workingFolder\src\Testing\Security\ThreadFix\tfcli.jar --set url THREADFIXURL"
iex "java -jar $workingFolder\src\Testing\Security\ThreadFix\tfcli.jar --upload APPNUMBER $workingFolder\fortify-report.fpr"