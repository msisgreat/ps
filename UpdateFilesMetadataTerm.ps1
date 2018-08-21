Add-Type -Path ".\CSOM\Microsoft.SharePoint.Client.dll"
Add-Type -Path ".\CSOM\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path ".\CSOM\Microsoft.SharePoint.Client.Taxonomy.dll"

$global:CopiedCount = 0
$username = "<user name>"
$password = "<pwd>"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword)

$destUrl = "<site URL>"
$destLibrary = "Documents"
$destinationFolder = "/sites/<site Name>/Shared Documents/<folder name if any>/"
$termName= "MyTerm"
$termGUID = "TERM GUID HERE"
$termWssId = wssid ## wssid of the term, you can find it from hiddentaxonomy list and the ID of the term in that list <siteurl>/Lists/TaxonomyHiddenList/AllItems.aspx
$libFieldColumnName = "ColumnName"


########
function UpdateFileColumns
{
    param($sourceFileCopy, $fListItem)   
        try{
        $modDate = $fListItem["Modified"]
        $modUser = $fListItem["Editor"]
        
        $termValue = New-Object Microsoft.SharePoint.Client.Taxonomy.TaxonomyFieldValue
        $termValue.Label = $termName #provide the term label here to change
        $termValue.TermGuid = $termGUID # term GUID here
        $termValue.WssId = $termWssId
        $taxField.SetFieldValueByValue($fListItem, $termValue)
        $fListItem["Modified"] = $modDate
        $fListItem["Editor"] = $modUser
        $fListItem.Update()
        $destContext.Load($fListItem)
        $destContext.ExecuteQuery()      
        $global:CopiedCount = $global:CopiedCount +1
        Write-Host "Updated the file. File Count: " $global:CopiedCount -ForegroundColor Cyan       
        }catch{
            $statusRemark = $statusRemark + "Creation error: " + $_.Exception.Message
            Write-Host $statusRemark -ForegroundColor Red
        } 
}

function CreateFolders
{ 
    param (
        [Parameter(Mandatory=$true)] $srcfolder        
        )

    $fileCol = $srcfolder.Files    
    $destContext.Load($fileCol)
    $destContext.ExecuteQuery()
    foreach ($f in $fileCol)
    {                          
        $ListItem = $f.ListItemAllFields                         
        $destContext.Load($f)
        $destContext.Load($ListItem)
        $destContext.ExecuteQuery()
        Write-Host "Updating file : " $f.ServerRelativeUrl                                                 
        UpdateFileColumns $f $ListItem

    } ## end of for each file
    $fL1FolderColl = $srcfolder.Folders
    $destContext.Load($fL1FolderColl);
    $destContext.ExecuteQuery();
    foreach ($myFolder in $fL1FolderColl)
    {
        $destContext.Load($myFolder)
        $destContext.ExecuteQuery()
        CreateFolders $myFolder
    }
} 

$destContext = New-Object Microsoft.SharePoint.Client.ClientContext($destUrl) 
$destContext.Credentials = $credentials
$destContext.RequestTimeout = 1000 * 60 * 10
try
{
    $destWeb = $destContext.Web
    $destList = $destWeb.Lists.GetByTitle($destLibrary)
    $destContext.Load($destWeb)
    $destContext.Load($destList)
    $field = $destList.Fields.GetByInternalNameOrTitle($libFieldColumnName) # column Name here 
    $destContext.Load($field)
    $destContext.ExecuteQuery()
}
catch{
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}

$taxField = [Microsoft.SharePoint.Client.ClientContext].GetMethod("CastTo").MakeGenericMethod([Microsoft.SharePoint.Client.Taxonomy.TaxonomyField]).Invoke($destContext, $field)

$folder = $destWeb.GetFolderByServerRelativeUrl($destinationFolder)
$destContext.Load($folder)
$destContext.ExecuteQuery()    
CreateFolders $folder
$destContext.Dispose()
$now=Get-Date -format "dd-MMM-yyyy HH:mm"
Write-Host "Script End : '$($now)'"
##############
