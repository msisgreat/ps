Add-Type -Path "C:\Documents\PS\CSOM\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Documents\PS\CSOM\Microsoft.SharePoint.Client.Runtime.dll"
 
$username = "name@domain.com"
$password = ""
$destUrl = "" ## https://site
$srcLibrary = "Documents"
 
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword)
 
Write-Host "connecting..."
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($destUrl)
$ctx.Credentials = $credentials
$srcWeb = $ctx.Web
$srcList = $srcWeb.Lists.GetByTitle($srcLibrary)
$ctx.Load($srcWeb)
$ctx.Load($srcList)
$ctx.ExecuteQuery()
Write-Host "connected"
 
Write-Host "uploading..."
$root = $srcList.RootFolder
$ctx.Load($root);
$ctx.ExecuteQuery()
$folder = $root.Folders
$ctx.Load($folder);
$ctx.ExecuteQuery()
foreach($f in $folder)
{
    $ctx.Load($f)
    $ctx.ExecuteQuery()
    Write-Host $f.Name
    if($f.Name -eq "Forms")
    {
        Write-Host "Inside " $f.Name
        $fci = New-Object Microsoft.SharePoint.Client.FileCreationInformation
        $fci.Content = [System.IO.File]::ReadAllBytes("C:\client_LocationBasedDefaults.html");
        $fci.Url = "client_LocationBasedDefaults.html";
        $fci.Overwrite = $true;
        $fileToUpload = $f.Files.Add($fci);
        $ctx.Load($fileToUpload);
        $ctx.ExecuteQuery()
        Write-Host "Uploaded .. "
    }
}
Write-Host "End Script" 
Share this: