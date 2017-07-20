function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
		[System.String]
		$Path,

        [parameter(Mandatory = $true)]
		[System.String]
		$Shortcut,

		[System.String]
		$Arguments
	)

	process 
    {
        return @{
            Path = $Path
            Shortcut = $Shortcut
            Arguments = $Arguments
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
		$Path,

        [parameter(Mandatory = $true)]
		[System.String]
		$Shortcut,

		[System.String]
		$Arguments
	)
	
    process
    {
        # Creates a desktop shortcut available to all based on a given path and arguments

        $WScriptShell = New-Object -ComObject WScript.Shell
    
        if($Path -match "\.lnk$")
        {
            $Path = $WScriptShell.CreateShortcut($Path).TargetPath
        }

        $output = $WScriptShell.CreateShortcut($Shortcut)

        $output.TargetPath = $Path
        $output.Arguments = $Arguments
        $output.Save()
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
		$Path,

        [parameter(Mandatory = $true)]
		[System.String]
		$Shortcut,

		[System.String]
		$Arguments
	)
    
    process
    {
        return Test-Path $Shortcut
    }
}

Export-ModuleMember -Function *-TargetResource

