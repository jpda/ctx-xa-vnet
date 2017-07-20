function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
		[System.String]
		$DeploymentFQDN,

        [parameter(Mandatory = $true)]
		[System.String]
		$GatewayFQDN,

        [parameter(Mandatory = $true)]
		[System.String]
		$EmailAddress,
        
        [parameter(Mandatory = $true)]
		[System.String]
		$IisRoot,

		[System.String]
		$Server = $configUrl
	)

    process
    {
	    return @{
            DeploymentFQDN = $DeploymentFQDN
            GatewayFQDN = $GatewayFQDN
            EmailAddress = $EmailAddress
            Server = $Server
            IisRoot = $IisRoot
	    }
    }
}

function Set-TargetResource
{
	[CmdletBinding()]
    param
	(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
		[System.String]
		$DeploymentFQDN,

        [parameter(Mandatory = $true)]
		[System.String]
		$GatewayFQDN,

        [parameter(Mandatory = $true)]
		[System.String]
		$EmailAddress,

        [parameter(Mandatory = $true)]
		[System.String]
		$IisRoot,

		[System.String]
		$Server = $configUrl
	)
	
    process
    {
        # Adds entries in the domain mapping service for this deployment

        $subdomain = Get-AzureSubdomain($GatewayFQDN)
        $deploymentId = (Get-DeploymentID)
    
        $domainBody = @{
            CNAME = $DeploymentFQDN
        }

        $result = Invoke-RestMethod -Uri "$Server/$subdomain" -Method Put -Body ($domainBody | ConvertTo-Json) `
                                    -ContentType "application/json"

        $deploymentBody = @{
            EmailAddress = $EmailAddress
        }

        $result = Invoke-RestMethod -Uri "$Server/$subdomain/deployments/$deploymentID" -Method Put `
                                    -Body ($deploymentBody | ConvertTo-Json) -ContentType "application/json"
    }
}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
		[System.String]
		$DeploymentFQDN,

        [parameter(Mandatory = $true)]
		[System.String]
		$GatewayFQDN,

        [parameter(Mandatory = $true)]
		[System.String]
		$EmailAddress,

        [parameter(Mandatory = $true)]
		[System.String]
		$IisRoot,

		[System.String]
		$Server = $configUrl
	)
	
    process
    {
        # Check for an entry for both the subdomain and this particular deployment

        $subdomain = Get-AzureSubdomain($GatewayFQDN)
        $deploymentId = (Get-DeploymentID)

        try
        {
            $result = Invoke-RestMethod -Uri "$Server/$subdomain" -Method Get

            if($result.CNAME -ne $DeploymentFQDN)
            {
                return $false
            }

            $result = Invoke-RestMethod -Uri "$Server/$subdomain/deployments/$deploymentID" -Method Get
        }
        catch [System.Net.WebException] 
        {
            if($_.Exception.Response.StatusCode -eq 404)
            {
                return $false
            }
            else
            {
                throw $_.Exception
            }
        }

        return $true
    }
}

<#
    .SYNOPSIS
        Tests whether or not a domain is properly formed for the marketplace solution and returns the 
        subdomain if well formed.
    .NOTES
        Must be a subdomain of xenapponazure.com
    .PARAMETER domain
        The domain to be tested for conformance
#>
function Get-AzureSubdomain([String]$domain)
{
    if($domain -match "^(?<subdomain>[a-z][\-a-z0-9]{1,61}[a-z0-9]-[\-a-z0-9]{3,30})\.xenapponazure\.com$")
    {
        return $Matches["subdomain"]
    }
    
    throw "Invalid domain specified"
}

<#
    .SYNOPSIS
        Gets an ID which uniquely identifies the entire deployment
    .NOTES
        Currently uses the Active Directory controller as the common reference point for all machines
#>
function Get-DeploymentID()
{
  $retries = 0

  while($retries -lt 10)
  {
    try
    {
      $guid = (Get-ADDomainController).ServerObjectGuid.ToString()

      $hasher = new-object System.Security.Cryptography.MD5CryptoServiceProvider
      $toHash = [System.Text.Encoding]::UTF8.GetBytes($guid)
      $hashByteArray = $hasher.ComputeHash($toHash)
      foreach($byte in $hashByteArray)
      {
        $result += "{0:X2}" -f $byte
      }
      return $result;
    }
    catch
    {
      Write-Verbose "Error retrieving domain deployment ID, retrying..."
      Start-Sleep -Seconds 120
      $retries = $retries + 1
    }
  }
  
  throw "Exceeding maximum retries retrieving domain deployment ID."
}

$configUrl = "http://citrixxenappconfig.azurewebsites.net/api/xasubdomain"
$iisRoot = ""

Export-ModuleMember -Function *-TargetResource

