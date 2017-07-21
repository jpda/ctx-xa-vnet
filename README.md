# ctx-xa-vnet

## Azure ARM template for deploying the [Citrix XenApp Trial marketplace offering](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/citrix.citrix-xa?tab=Overview) to an existing VNet and Active Directory domain

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjpda%2Fctx-xa-vnet%2Fmaster%2Ftemplate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjpda%2Fctx-xa-vnet%2Fmaster%2Ftemplate.json" target="_blank">
    <img src="http://azuredeploy.net/AzureGov.png"/>
</a>

# Notes + Issues
## Structure
- Each VM in the template is created via nested templates
- There are two net-new templates, `virualNetwork-existing` and `-new.json` - these are to support 'create if not exists' 
- These net-new templates are referenced via the `extArtifactsBaseUrl` parameter, so they don't impact the existing Citrix-built artifacts
- As of now, none of the original Citrix nested templates have been modified, so they still live at their original locations
- This uses four individual marketplace images - NetScaler 11.1 VPX BYOL, XenApp Server, XenApp VDA (RSDH) and XenApp VDA (VDI)

## ⚠️⚠️ Programmatic deployment ⚠️⚠️
You _will_ get an error if you attempt to deploy this (or any marketplace template requiring acceptance of license terms) into a subscription where you have not accepted the terms (e.g., clicked the 'Purchase' button in the portal) before. If you do, you will receive a `code=MarketplacePurchaseEligibilityFailed` error on deployment. To get past this, 
- Deploy the template via the portal into a new resource group
- WAIT until it finishes deploying (as each indivdual offer must deploy before being considered 'accepted')
- delete the resource group
- verify via the portal that programmatic access is allowed for the specific SKUs
    - More Services --> Subscriptions --> Subscription --> Programmatic deployment

## Issues
- The `adminUsername` and `adminPassword` parameters need to match a domain user with rights to join machines to the domain
    - this is due to the original template assuming it was creating a brand new AD domain, reusing the same user/pass for local and domain principals
    - you can use a domain admin account (not recommended) or create new user and pre-stage the machines, giving the new user permission to join the machines to the domain
    - you can find the machine names in the template

## Other
Offered as-is, without warranty.