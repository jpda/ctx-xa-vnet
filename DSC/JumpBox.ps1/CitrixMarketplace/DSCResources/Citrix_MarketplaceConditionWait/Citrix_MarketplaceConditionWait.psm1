function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Condition,

        [System.String]
        $Machine="localhost",

        [System.String]
        $Share = "Status",

        [System.String]
        $Content = "Complete",

        [System.Boolean]
        $Reboot = $false,

        [Int]$RetryCount = 50,
        [Int]$RetryIntervalSec = 60
    )

    process
    {
	   return @{
            Machine = $Machine
            Condition = $Condition
            Content = $Content
            Share = $Share
            Reboot = $Reboot
        }
    }
}

function Set-TargetResource
{
	[CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Condition,

        [System.String]
        $Machine="localhost",

        [System.String]
        $Share = "Status",

        [System.String]
        $Content = "Complete",

        [System.Boolean]
        $Reboot = $false,

        [Int]$RetryCount = 50,
        [Int]$RetryIntervalSec = 60
    )
	
    begin
    {
        $path = "\\$Machine\$Share\$Condition"
    }

    process
    {
        for($i = 0; $i -lt $RetryCount; $i++)
        {
            try
            {
                if(Test-Path "$path")
                {
                    if((Get-Content -LiteralPath $Path) -match $Content)
                    {
                        Write-Verbose "Condition observed, stopping wait"

                        if($Reboot -and ($i -gt 5))
                        {
                            Write-Verbose "Observed a changed condition requiring a reboot. Setting reboot flag."
                            $global:DSCMachineStatus = 1
                        }

                        return

                    }
                    else
                    {
                        Write-Verbose "Condition observed, but not in desired state, retrying..."
                    }
                }
                else
                {
                    Write-Verbose "Condition not observed, retrying..."

                    if($i -eq ($RetryCount/2))
                    {
                        Write-Verbose "Attempting reset of network adapter."
                        Get-NetAdapter | Reset-NetAdapter
                    }
                    else
                    {
                      Clear-DnsClientCache
                    }
                }
            }
            catch
            {
                Write-Verbose "Error in checking status, retrying..."
            }

            Start-Sleep -Seconds $RetryIntervalSec
        }

        throw "Exhausted retries waiting for condition."
    }
}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Condition,

        [System.String]
        $Machine="localhost",

        [System.String]
        $Share = "Status",

        [System.String]
        $Content = "Complete",

        [System.Boolean]
        $Reboot = $false,

        [Int]$RetryCount = 50,
        [Int]$RetryIntervalSec = 60
    )

    begin
    {
        $path = "\\$Machine\$Share\$Condition"
    }

    process
    {
        Write-Verbose "Path: $path"

        try
        {
            if(Test-Path $path)
            {
                return (Get-Content -LiteralPath $Path) -match $Content
            }
        }
        catch 
        {
            Write-Verbose "Error checking condition, not in desired state..."
        }

        return $false
    }
}

Export-ModuleMember -Function *-TargetResource

