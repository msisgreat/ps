Add-Type -Path "C:\Users\altfo\Downloads\CSOM\net\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Users\altfo\Downloads\CSOM\net\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Users\altfo\Downloads\CSOM\net\Microsoft.SharePoint.Client.UserProfiles.dll"

$username = "<UID>"
$password = "<PWD>"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword)
Write-Host "Connecting to site ..."
$srcUrl = "<SITE>" ## https://sitename/sites/sitename

$srcContext = New-Object Microsoft.SharePoint.Client.ClientContext($srcUrl)
$srcContext.Credentials = $credentials
#$srcWeb = $srcContext.Web
$srcContext.ExecuteQuery()
Write-Host "Connected successfully"
try{  
    $peopleManager = New-Object Microsoft.SharePoint.Client.UserProfiles.PeopleManager($srcContext)                  
    $peopleManager.SetSingleValueProfileProperty("<full acc name>", "AboutMe>", "I eat sleep drink microsoft")  
    $srcContext.Load($peopleManager)  
    $srcContext.ExecuteQuery()  
    Write-Host "Property updated"  
}  
catch{  
    Write-Host "$($_.Exception.Message)" -foregroundcolor Red  
}  
