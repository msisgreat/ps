Add-Type -Path "C:\Documents\PS\CSOM\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Documents\PS\CSOM\Microsoft.SharePoint.Client.Runtime.dll"

$now=Get-Date -format "dd-MMM-yy,HH:mm:ss"
$fileFormat = Get-Date -format "dd-MMM-yy_HHmmss"
Write-Host "Script Start : '$($now)'" -ForegroundColor Yellow

$global:OutFilePath = "C:\reports\site_groups_" + $fileFormat + ".csv"
$header = "Date,Time,Group Id,Group Name,Users List"
Add-Content -Path $global:OutFilePath -Value "`n $header"  

$username = "<UserID>"
$password = "<PWD>"
$srcUrl = "<SITE URL>"

$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword)

function WriteLog
{
    param (
            [Parameter(Mandatory=$true)] $Values
            )
    $nowTime=Get-Date -format "dd-MMM-yy,HH:mm:ss"    
    $lineContent = "$($nowTime)"
    foreach($content in $Values)
    {
        #$content = $content.Replace(",","|")
        $lineContent = $lineContent + "," + $content
    }
    Add-Content -Path $global:OutFilePath -Value "$lineContent"
}

### The script starts here to run ####
Write-Host "Authenticating ..." -ForegroundColor White
$srcContext = New-Object Microsoft.SharePoint.Client.ClientContext($srcUrl) 
$srcContext.Credentials = $credentials
$srcWeb = $srcContext.Web
$srcContext.Load($srcWeb)
$srcContext.ExecuteQuery()
Write-Host "Connected to the web..." -ForegroundColor Cyan

$spoGroups=$srcContext.Web.SiteGroups
$srcContext.Load($spoGroups)   
$srcContext.ExecuteQuery()
$arrayValue = $null
foreach($item in $spoGroups)
{
    #$srcContext.Load($item)
    #$srcContext.ExecuteQuery()
    $arrayValue = @()
    Write-Host $item.Title "Id = " $item.Id
    $arrayValue = @($item.Id,$item.Title.Replace(",","|"))
    
    try
    {
        $spoUsers=$item.Users
        $srcContext.Load($spoUsers)
        $srcContext.ExecuteQuery()
        $userList = ""

        foreach($itemUser in $spoUsers)
        {
            $userList = $userList + $itemUser.Email + ";"
        }
        $arrayValue +=$userList
        WriteLog $arrayValue    
    }
    catch{
    $arrayValue += $_.exception.message
    WriteLog $arrayValue
    }
    
}
$srcContext.dispose()
$now=Get-Date -format "dd-MMM-yy,HH:mm:ss"
Write-Host "END Start : '$($now)'" -ForegroundColor Yellow
