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
 
#### Step 1: download the html file
        # Get forms folder in library
        $formsFolder = $srcList.RootFolder.Folders.GetByUrl("Forms")
        $ctx.Load($formsFolder)
        $ctx.ExecuteQuery()
 
        # Get client_LocationBasedDefaults.html file in forms library
        $LocationBasedDefaultsXML = $formsFolder.Files.GetByUrl('client_LocationBasedDefaults.html')
        $ctx.Load($LocationBasedDefaultsXML)
        $ctx.ExecuteQuery()
 
        # Download file
        $fileInfo = [Microsoft.SharePoint.Client.File]::OpenBinaryDirect($ctx, $LocationBasedDefaultsXML.ServerRelativeUrl)
        $fstream = New-Object System.IO.FileStream("C:\client_LocationBasedDefaults.html", [System.IO.FileMode]::Create);
        $fileInfo.Stream.CopyTo($fstream)
        $fstream.Flush()
        $fstream.Close()
    Write-Host "Downloaded the file successfully"
