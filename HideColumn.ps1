Add-Type -Path "C:\Documents\PS\CSOM\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Documents\PS\CSOM\Microsoft.SharePoint.Client.Runtime.dll"
$username = "username@domain.com"
$password = "<password>"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword)
Write-Host "Connecting to site ..."
$srcUrl = "<url>" ## https://sitename/sites/sitename
$srcLibrary = "Leave Application"
$srcContext = New-Object Microsoft.SharePoint.Client.ClientContext($srcUrl)
$srcContext.Credentials = $credentials
$srcWeb = $srcContext.Web
$srcList = $srcWeb.Lists.GetByTitle($srcLibrary)
$srcContext.Load($srcList)
$srcContext.ExecuteQuery()
Write-Host "Connected successfully"
 
$fields = @("Application Status","Approver Comment")
foreach($fieldname in $fields)
{
    Write-Host "Hiding from edit & new form: " $fieldname
    $fieldToEdit = $srcList.Fields.GetByTitle($fieldname);
    $srcContext.Load($fieldToEdit)
    $srcContext.ExecuteQuery()
    $fieldToEdit.SetShowInEditForm($false)
    #$fieldToEdit.Update()
    $srcContext.ExecuteQuery()
    $fieldToEdit.SetShowInNewForm($false)
    #$fieldToEdit.Update()
    $srcContext.ExecuteQuery()
    #$srcWeb.Update()
 
}