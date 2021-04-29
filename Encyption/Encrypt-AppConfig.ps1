param
(
	[ValidateScript({Test-Path $_})]
	[Parameter(Mandatory=$true,HelpMessage='folder containing config files')]
	[string]$folder,
	[Parameter(Mandatory=$true,HelpMessage='target environment for the config (helps determine which kms key to use')]
	[string]$env,
	[Parameter(Mandatory=$true,HelpMessage='target region for the config (helps determine which kms key to use')]
	[string]$region,
	[Parameter()]
	[switch]$removeUnencrypted=$true,
	[Parameter()]
	[string]$profileName
)


function Invoke-KMSEncryptFile
(
	[ValidateScript({Test-Path $_})]
	[Parameter(Mandatory=$true,HelpMessage='Path to file to be Encrypt')]
	[string]$filePath,
	[Parameter(Mandatory=$true,HelpMessage='Id of encryption key in KMS (e.g alias/name, or guid)')]
	[string]$keyId,
	[Parameter(Mandatory=$true,HelpMessage='aws region for the key')]
	[string]$region,
	[Parameter()]
	[string]$profileName
)
{
	$outPath = $filePath + ".enc";
	Write-Host "[Invoke-KMSEncryptFile] started (filePath: $filePath; keyId: $keyId; region: $region; profileName: $profileName)"

	# setup
	$bufferLength = 2048
	$source = [System.IO.File]::OpenRead($filePath)
	$output = [System.IO.File]::CreateText($outPath)
	
	# encrypt
	$offset = 0
	while ($offset -lt $source.Length)
	{	
		if (($offset + $bufferLength) -gt $source.Length)
		{
			$remainder = (($source.Length - $offset))
			$buffer = New-Object System.Byte[] -ArgumentList $remainder
			$bytesRead = $source.Read($buffer,0,$remainder)
		}
		else
		{
			$buffer = New-Object System.Byte[] -ArgumentList $bufferLength
			$bytesRead = $source.Read($buffer,0,$bufferLength) 
		}
		
		$memoryStream = New-Object System.IO.MemoryStream($buffer,0,$buffer.Length)
		$encryptedMemoryStream = Invoke-KMSEncrypt -Plaintext $memoryStream -KeyId $keyId -Region $region -ProfileName $profileName
		$base64encrypted = [System.Convert]::ToBase64String($encryptedMemoryStream.CiphertextBlob.ToArray())
		$output.WriteLine($base64encrypted)
		$offset += $bufferLength
    }
	$source.Dispose()
	$output.Dispose()

	Write-Host (Get-Date) "Encrypted $filePath to $outPath with KeyId: $keyId" -ForegroundColor Green -BackgroundColor Black

	if ($removeUnencrypted) {
		Remove-Item $filePath
		Write-Host (Get-Date) "Removed $filePath" -ForegroundColor Green -BackgroundColor Black
	}

	return $outPath
}

$filePath = "$folder/$env-specific-paramstore.json"
if (![System.IO.Path]::IsPathRooted($filePath)) {
	$filePath = "$PSScriptRoot/$filePath";
}

$keyId = "alias/project-$env-kms-$region-config"


$out = Invoke-KMSEncryptFile -filePath $filePath -keyId $keyId -region $region -profileName $profileName

return $out