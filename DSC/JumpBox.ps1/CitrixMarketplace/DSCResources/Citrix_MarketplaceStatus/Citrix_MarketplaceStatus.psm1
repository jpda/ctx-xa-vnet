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
		$MachineName,
        
        [parameter(Mandatory = $true)]
		[ValidateSet("Started","Succeeded","Failed")]
        [System.String]
		$Status,

		[System.String]
		$Server = $configUrl
	)

    process
    {
	    return @{
            DeploymentID = $DeploymentID
            DeploymentFQDN = $DeploymentFQDN
            GatewayFQDN = $GatewayFQDN
            MachineName = $MachineName
            Status = $Status
            Server = $Server
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
		$MachineName,
        
        [parameter(Mandatory = $true)]
		[ValidateSet("Started","Succeeded","Failed")]
        [System.String]
		$Status,

		[System.String]
		$Server = $configUrl
	)
	
    process
    {
        # Updates the notification service as to the status of this machine in the deployment

        $subdomain = Get-AzureSubdomain($GatewayFQDN)
        $deploymentId = (Get-DeploymentID)
	
        $statusBody = @{
            Status = $Status
        }

        $result = Invoke-RestMethod -Uri "$Server/$subdomain/deployments/$deploymentId/machines/$MachineName" `
                                    -Method Put -Body ($statusBody | ConvertTo-Json) -ContentType "application/json"
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
		$MachineName,
        
        [parameter(Mandatory = $true)]
		[ValidateSet("Started","Succeeded","Failed")]
        [System.String]
		$Status,

		[System.String]
		$Server = $configUrl
	)


    process
    {
        $subdomain = Get-AzureSubdomain($GatewayFQDN)
	    $deploymentId = (Get-DeploymentID)
    
        # Checks for a status entry on this particular machine in the deployment
        try
        {
            $result = Invoke-RestMethod -Uri "$Server/$subdomain/deployments/$deploymentId/machines/$MachineName" `
                                        -Method Get

            return ($result.Status -eq $Status)
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

        return $false
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

Export-ModuleMember -Function *-TargetResource

