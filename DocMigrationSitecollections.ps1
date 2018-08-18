
Add-Type -Path ".\CSOM\Microsoft.SharePoint.Client.dll"
Add-Type -Path ".\CSOM\Microsoft.SharePoint.Client.Runtime.dll"
$username = "name@domain.com"
$password = ""
$srcUrl = "" ## use the full URL of the site
$destUrl = "" ## use the full URL of the site
$srcLibrary = ""
$destLibrary = ""
$destinationFolder = "/sites//Shared Documents//" ## Make sure the folder name ends with /
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword)
function CreateFolders
{
param (
[Parameter(Mandatory=$true)] $srcfolder,
[Parameter(Mandatory=$true)] [string] $destFolderPath
)
Write-Host "Source Folder:" + $srcfolder.Name + " dest folder:" + $destFolderPath -ForegroundColor Yellow
$SPOFolder = $destWeb.GetFolderByServerRelativeUrl($destFolderPath)
$FolderName = $srcfolder.Name
$NewFolder = $SPOFolder.Folders.Add($FolderName)
$destWeb.Context.Load($NewFolder)
$destWeb.Context.ExecuteQuery()
Write-Host "Folder Created - " + $FolderName -ForegroundColor Yellow
## get source folder details
$SrcFolderListItem = $srcfolder.ListItemAllFields
$srcContext.Load($SrcFolderListItem)
$srcContext.ExecuteQuery()
####
$SPOFolderItem = $NewFolder.ListItemAllFields;
$replacedUser =$destWeb.EnsureUser($SrcFolderListItem["Editor"].Email)
$SPOFolderItem["Editor"] = $replacedUser
$replacedUser =$destWeb.EnsureUser($SrcFolderListItem["Author"].Email)
$SPOFolderItem["Author"] = $replacedUser
$SPOFolderItem["Created"] = $SrcFolderListItem["Created"]
$SPOFolderItem["Modified"] = $SrcFolderListItem["Modified"]
$SPOFolderItem.Update()
$destContext.Load($NewFolder)
$destContext.ExecuteQuery()
$fileCol = $srcfolder.Files
$srcContext.Load($fileCol)
$srcContext.ExecuteQuery()
### Load the file to hash table to check with Target library.
$hashFiles = @{}
$DestfileCol = $NewFolder.Files
$destContext.Load($DestfileCol)
$destContext.ExecuteQuery()
foreach ($destFile in $DestfileCol){
$hashFiles.add($destFile.Name,$destFile.Name)
}
foreach ($f in $fileCol)
{
if($hashFiles.ContainsKey($f.Name) -ne "true") ## check whether file name already exists
{
$srcContext.Load($f)
$srcContext.ExecuteQuery()
$id = $srcfolder.Name
$nLocation =$NewFolder.ServerRelativeUrl.TrimEnd("/") + "/" + $f.Name
Write-Host $nLocation
try
{
$fileInfo = [Microsoft.SharePoint.Client.File]::OpenBinaryDirect($srcContext, $f.ServerRelativeUrl)
[Microsoft.SharePoint.Client.File]::SaveBinaryDirect($destContext, $nLocation, $fileInfo.Stream,$true)
$ListItem = $f.ListItemAllFields
$srcContext.Load($ListItem)
$srcContext.ExecuteQuery()
$fileCreated = $destWeb.GetFileByServerRelativeUrl($nLocation)
$destContext.Load($fileCreated)
$destContext.ExecuteQuery()
$DestListItem = $fileCreated.ListItemAllFields;
$replacedUser =$destWeb.EnsureUser($ListItem["Editor"].Email)
$DestListItem["Editor"] = $replacedUser
$replacedUser =$destWeb.EnsureUser($ListItem["Author"].Email)
$DestListItem["Author"] = $replacedUser
$DestListItem["Created"] = $ListItem["Created"];
$DestListItem["Modified"] = $ListItem["Modified"];
$DestListItem.Update()
$destContext.Load($fileCreated)
$destContext.ExecuteQuery()
}
catch
{
Write-Host $_ -ForegroundColor Red
}
}
}
$fL1FolderColl = $srcfolder.Folders
$srcContext.Load($fL1FolderColl);
$srcContext.ExecuteQuery();
foreach ($myFolder in $fL1FolderColl)
{
$srcContext.Load($myFolder)
$srcContext.ExecuteQuery()
CreateFolders $myFolder $NewFolder.ServerRelativeUrl
}
}
#### The main script starts here ######
$srcContext = New-Object Microsoft.SharePoint.Client.ClientContext($srcUrl)
$srcContext.Credentials = $credentials
$destContext = New-Object Microsoft.SharePoint.Client.ClientContext($destUrl)
$destContext.Credentials = $credentials
$srcWeb = $srcContext.Web
$srcList = $srcWeb.Lists.GetByTitle($srcLibrary)
$query = New-Object Microsoft.SharePoint.Client.CamlQuery
$listItems = $srcList.GetItems($query)
$srcContext.Load($srcList)
$srcContext.Load($listItems)
$srcContext.ExecuteQuery()
$destWeb = $destContext.Web
$destList = $destWeb.Lists.GetByTitle($destLibrary)
$destContext.Load($destWeb)
$destContext.Load($destList)
$destContext.ExecuteQuery()
########### this is to copy only certain folders
#$folder = $srcWeb.GetFolderByServerRelativeUrl($srcFolder)
#$srcContext.Load($folder)
#$srcContext.ExecuteQuery()
#Write-Host $destinationFolder
#CreateFolders $folder $destinationFolder
##############
foreach($item in $listItems)
{
if($item.FileSystemObjectType -eq "File")
{
#$srcContext.Load($item)
#$srcContext.ExecuteQuery()
$srcF = $item.File
$srcContext.Load($srcF)
$srcContext.ExecuteQuery()
$rootLocation = $destinationFolder + $srcF.Name
Write-Host $rootLocation
$fileContent = [Microsoft.SharePoint.Client.File]::OpenBinaryDirect($srcContext, $srcF.ServerRelativeUrl)
[Microsoft.SharePoint.Client.File]::SaveBinaryDirect($destContext, $rootLocation, $fileContent.Stream,$true)
$fItem = $srcF.ListItemAllFields
$srcContext.Load($fItem)
$srcContext.ExecuteQuery()
$fCreated = $destWeb.GetFileByServerRelativeUrl($rootLocation)
$destContext.Load($fCreated)
$destContext.ExecuteQuery()
$DListItem = $fCreated.ListItemAllFields;
$replacedUser =$destWeb.EnsureUser($fItem["Editor"].Email)
$DListItem["Editor"] = $replacedUser
$replacedUser =$destWeb.EnsureUser($fItem["Author"].Email)
$DListItem["Author"] = $replacedUser
$DListItem["Created"] = $fItem["Created"];
$DListItem["Modified"] = $fItem["Modified"];
$DListItem.Update()
$destContext.Load($fCreated)
$destContext.ExecuteQuery()
}
elseif ($item.FileSystemObjectType -eq "Folder")
{
$srcContext.Load($item)
$srcContext.ExecuteQuery()
$folder = $srcWeb.GetFolderByServerRelativeUrl($item.FieldValues["FileRef"].ToString())
$srcContext.Load($folder)
$srcContext.ExecuteQuery()
##################
Write-Host $destinationFolder
CreateFolders $folder $destinationFolder
}
}
Write-Host “Script End"