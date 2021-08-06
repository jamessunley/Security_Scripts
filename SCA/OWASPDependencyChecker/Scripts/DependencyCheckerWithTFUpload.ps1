#Project ID
$PROJECT = "ProjectName"

#The location to scan
$SCAN = Split-Path -parent $MyInvocation.MyCommand.Definition | Split-Path -parent | Split-Path -parent | Split-Path -parent | Split-Path -parent

#Identify Suppression file
$SUPPRESSION = "\OWASPDependencyChecker\owasp-dependency-check-suppressions.xml"

#Exclusions
$EX = "--exclude `"\Dependencies\dynamodb_local\**`""
$EX = "$EX --exclude `"\Dependencies\UnNeededFolder\**`""
$EX = "$EX --exclude `"\Testing\**`""
$EX = "$EX --exclude `"\ProjectName.Tests\**`""
$EX = "$EX --exclude `"/**/*.Tests/**/*`""

#File to Output report to
$OUT = "\OWASPDependencyChecker\Reports"

#HTML file type
$HTML = "HTML"

#XML file type
$XML = "XML"

#Output location to scan
Write-Output $SCAN

#Set working folder - based on location of the script
$workingFolder = Split-Path -parent $MyInvocation.MyCommand.Definition | Split-Path -parent | Split-Path -parent

#Output working folder
Write-Output $workingFolder

#Scan 1 - HTML file, so vulnerabilities can be viewed in browser
"Started Scan 1"
iex "C:\dependency-check\bin\dependency-check.bat --project `"$PROJECT`" --scan `"$SCAN`" --suppression `"$workingFolder$SUPPRESSION`" $EX --out `"$workingFolder$OUT`" -f $HTML"
"Scan 1 produced an HTML file - use this file to easily see dependency flaws"

#Scan 2 - XML file, to be uploaded to ThreadFix
"Started Scan 2"
iex "C:\dependency-check\bin\dependency-check.bat --project `"$PROJECT`" --scan `"$SCAN`" --suppression `"$workingFolder$SUPPRESSION`" $EX --out `"$workingFolder$OUT`" -f $XML"
"Scan 2 produced XML file - use this file to upload results to ThreadFix"

"OWASP dependency scan complete"

#Upload to ThreadFix
"Uploading to ThreadFix"

#Key and address to upload to ThreadFix
iex "java -jar $workingFolder\ThreadFix\tfcli.jar --set key APIKEY"
iex "java -jar $workingFolder\ThreadFix\tfcli.jar --set url THREADFIXURL"
iex "java -jar $workingFolder\ThreadFix\tfcli.jar --upload 223 $workingFolder\OWASPDependencyChecker\Reports\dependency-check-report.xml"