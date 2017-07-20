#
# JumpBox.ps1
#
configuration JumpBox 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [Hashtable[]]$Shortcuts
    ) 

    Import-DscResource -ModuleName CitrixMarketplace, xSystemSecurity

	$desktopPath = "C:\Users\Public\Desktop"

    Node localhost
    {
        LocalConfigurationManager 
        { 
            RebootNodeIfNeeded = $true
			ConfigurationMode = "ApplyOnly"
        } 

		foreach($shortcut in $Shortcuts) 
		{
			Citrix_MarketplaceShortcut $shortcut.name
			{
				Path = $shortcut.path
				Shortcut = $desktopPath + "\" + $shortcut.name + ".lnk"
				Arguments = $shortcut.arguments
			}
		}

		xIEEsc DisableIEEscUsers
        { 
            IsEnabled = $false 
            UserRole = "Users" 
        } 

        xIEEsc DisableIEEscAdministrators
        { 
            IsEnabled = $false 
            UserRole = "Administrators" 
        } 
    }
}