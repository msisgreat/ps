#### To change the webpart view 
#### Get the webpart from the page. get the WebPart XmlDef and find the View ID
### List has hidden view for the web part added. So get the view from the List and change that view.
### Its all about that hidden View

Add-Type -Path ".\CSOM\Microsoft.SharePoint.Client.dll"
Add-Type -Path ".\CSOM\Microsoft.SharePoint.Client.Runtime.dll"

$now=Get-Date -format "dd-MMM-yy,HH:mm:ss"
$fileFormat = Get-Date -format "dd-MMM-yy_HHmmss"
Write-Host "Script Start : '$($now)'" -ForegroundColor Yellow

$username = "<user id>"
$password = "<pwd>"
$srcUrl = "<site url>" # full url like hhtp://my.sharepoint.com/
$sitePath = "/SitePages/"
$srcLibrary = "Documents"
$pagesList = @("Home.aspx") # you can specify many pages to be changed array here
$wepPartChangeList = @{"Documents" = "All Documents" ; } ### dictionary value Key = Web part Title seen on page, Value = View Name from the Library

$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword)

Write-Host "Authenticating ..." -ForegroundColor White
$srcContext = New-Object Microsoft.SharePoint.Client.ClientContext($srcUrl) 
$srcContext.Credentials = $credentials
$srcWeb = $srcContext.Web
$srcList = $srcWeb.Lists.GetByTitle($srcLibrary)

$srcContext.Load($srcWeb)
$srcContext.Load($srcList)


try{
    $srcContext.ExecuteQuery()
}catch{
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}
Write-Host "Connected to the web..." -ForegroundColor Green

foreach($page in $pagesList)
{
    $filePath = $sitePath + $page
    $pageObject = $srcWeb.GetFileByServerRelativeUrl($filePath)
    $srcContext.Load($pageObject)
    $srcContext.ExecuteQuery()
    $WPM = $pageObject.GetLimitedWebPartManager("Shared")

    $webParts = $WPM.WebParts
    $srcContext.Load($WPM)
    $srcContext.Load($webParts)
    $srcContext.ExecuteQuery()

    foreach($wp in $webParts)
    {
        $srcContext.Load($wp.WebPart)
        $srcContext.Load($wp.WebPart.Properties)
        $srcContext.ExecuteQuery()

        if( $wepPartChangeList[$wp.WebPart.Title] -ne $null) 
        #if($wp.WebPart.Title.IndexOf("Documents") -gt 0)
        {
            Write-Host "---------- Processing Page  = $($pageObject.Name) Webpart = $($wp.WebPart.Title) ------- " -ForegroundColor Yellow

            $wpXmlContent = $wp.WebPart.Properties["XmlDefinition"]
            $wpXml = New-Object -TypeName XML
            $wpXml.LoadXml($wpXmlContent)
            $viewGUID = $wpXml.View.Name

            $viewName = $null
            $viewName = $wepPartChangeList[$wp.WebPart.Title]
            if($viewName)
            {
                $view = $srcList.Views.GetByTitle($viewName)
                $wpView = $srcList.Views.GetById($viewGUID)
                $srcContext.Load($wpView)
                $srcContext.Load($view)
                $srcContext.ExecuteQuery()               
                #$viewXml = New-Object -TypeName XML
                #$viewXml.LoadXml($view.ListViewXml)                    
                write-host "### WebPart Xml -------Before Xml Change -----" -foreground cyan
                write-host "$($wpView.ListViewXml)"              

                $wpViewFields = $wpView.ViewFields
                $viewFields = $view.ViewFields
                $srcContext.Load($viewFields)
                $srcContext.Load($wpViewFields)
                $srcContext.ExecuteQuery()

                $wpViewFields.RemoveAll()
                foreach($vField in $viewFields)
                {
                    $wpView.ViewFields.Add($vField)
                }
                
                $wpView.RowLimit = $view.RowLimit
                $wpView.ViewQuery = $view.ViewQuery                
                $wpView.Update() 
                $srcContext.Load($wpView) 
                $srcContext.ExecuteQuery() 
                write-host "### WebPart Xml -------After Xml Change -----" -foreground cyan
                write-host "$($wpView.ListViewXml)" 
                write-host "*******************************************************************" -foreground cyan
            }
            else
            {
                Write-Host "Unable to fing view for " $wp.WebPart.Title -ForegroundColor Cyan
            }
            #$wp.SaveWebPartChanges()
           
        }
    }
    #Write-Host "Next Page " 

}
#>

$srcContext.Dispose()
$now=Get-Date -format "dd-MMM-yy,HH:mm:ss"
Write-Host "END : '$($now)'" -ForegroundColor Yellow
