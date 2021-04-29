param
(
	[ValidateScript({Test-Path $_})]
	[Parameter(Mandatory=$true,Position=1,HelpMessage='folder storing config files')]
	[string]$folder,
	[Parameter(Mandatory=$true,HelpMessage='target environment for the config (helps determine which kms key to use')]
	[string]$env,
	[Parameter(Mandatory=$true,Position=3,HelpMessage='aws region for the key')]
	[string]$region,
	[Parameter()]
	[string]$profileName
)

function Invoke-KMSDecryptFile
(
	[ValidateScript({(Test-Path $_) -and ($_ -match "^.*.enc$")})]
	[Parameter(Mandatory=$true,Position=1,HelpMessage='Path to file to be decrypted, must end ".enc"')]
	[string]$filePath,
	[Parameter(Mandatory=$true)]
	[string]$region,
	[Parameter()]
	[string]$profileName
)
{
	$outPath = $filePath.Substring(0,($filePath.Length - 4))

	if (Test-Path $outPath)
	{
		Remove-Item -Path $outPath -Force
	}

	# setup
	$bufferLength = 2048
	$lines = @([System.IO.File]::ReadLines($filePath))
	$buffer = New-Object System.Byte[] -ArgumentList $bufferLength
	$output = New-Object System.IO.BinaryWriter -ArgumentList ([System.IO.File]::Open($outPath,[System.IO.FileMode]::Create))
	
	# decrypt
	$Activity = "Decrypt File"
	$linecount = 1
	foreach ($line in $lines)
	{
		## Displays the overall progress on the screen
		$percentComplete = [math]::round((($linecount/$lines.count) * 100), 0)
		Write-Progress -Activity $Activity -Status "Completed $($linecount * $bufferLength) of $($lines.count * $bufferLength) bytes" -PercentComplete $percentComplete -Id 1
		
		$encryptedBytes  = [System.Convert]::FromBase64String($line)
		$encryptedMemoryStreamToDecrypt = New-Object System.IO.MemoryStream($encryptedBytes,0,$encryptedBytes.Length)
		
		$decryptedMemoryStream = Invoke-KMSDecrypt -CiphertextBlob $encryptedMemoryStreamToDecrypt -Region $region -ProfileName $profileName
		
		$buffer = $decryptedMemoryStream.Plaintext.ToArray()
		
		$output.Write($buffer)
		$linecount++
    }
	Write-Progress -Activity $Activity -PercentComplete $percentComplete -Completed -Id 1
	$output.flush()
	$output.Dispose()
	Write-Host (Get-Date) "Decrypted $filePath to $outPath" -ForegroundColor Green -BackgroundColor Black

	return $outPath
}

$filePath = "$folder/$env-specific-paramstore.json.enc"
if (![System.IO.Path]::IsPathRooted($filePath)) {
	$filePath = "$PSScriptRoot/$filePath";
}

$out = Invoke-KMSDecryptFile -filePath $filePath -region $region -profileName $profileName

return $out
