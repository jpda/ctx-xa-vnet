Configuration Citrix_MarketplaceConditionSet
{  
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Condition,

        [System.String]
        $Content="Complete",

        [System.String]
        $Store = "C:\Status",

        [System.String]
        $Share = "Status"
    )

    Import-DscResource -Name MSFT_xSmbShare

    File Repository
    {
        Ensure = "Present"
        DestinationPath = $Store
        Type = "Directory"
            
    }

    xSmbShare Status 
    { 
        Ensure = "Present"  
        Name   = $Share 
        Path = $Store   
        Description = "DSC orchestration share"
        ReadAccess = "Everyone"
    }

    File Condition
    {
        DestinationPath = "$Store\$Condition"
        Contents = $Content
    }
}
