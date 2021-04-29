Param(
[Parameter(Mandatory=$true)][string]$REGION,
[Parameter(Mandatory=$true)][string]$ENV
)

########Get & Delete all APikeys associated with env and  ############
	$APIKeys =  aws apigateway get-api-keys --query "items[?starts_with(name, '$ENV')].id" --region $REGION --page-size 50 --output text

   IF ($ENV -like "dev*" -or $ENV -like "uat")
	{

		Write-Host "About to delete API Keys For : $ENV "

		foreach($apiKey in $APIKeys)
		{
		Write-Host "@@ APIKey Id :  $apiKey @@"
		aws apigateway delete-api-key --api-key $apiKey --region $REGION
		}
	}


