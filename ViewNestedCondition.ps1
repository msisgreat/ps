Add-Type -Path ".\CSOM\Microsoft.SharePoint.Client.dll"
Add-Type -Path ".\CSOM\Microsoft.SharePoint.Client.Runtime.dll"


$username = "USER ID" 
$password = "PWD" 
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force 
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword) 
Write-Host "Connecting to site ..." 
$srcUrl = "<site URL>" 

$srcContext = New-Object Microsoft.SharePoint.Client.ClientContext($srcUrl)  
$srcContext.Credentials = $credentials 
$srcWeb = $srcContext.Web 
$srcList = $srcWeb.Lists.GetByTitle(",DOC LIB>") 
$view = $srcList.Views.GetByTitle("<VIEW NAME>")


$srcContext.Load($srcWeb) 
$srcContext.Load($srcList) 
$srcContext.Load($view) 
$srcContext.ExecuteQuery() 
Write-Host "Connected successfully" 


$query =  @" 
  <OrderBy>
 <FieldRef Name="Modified" Ascending="FALSE" />
 </OrderBy>
 <Where><And><Or><Or><Eq><FieldRef Name="Editor" /><Value Type="User">senthamil</Value></Eq><Or><Eq><FieldRef Name="Editor" /> <Value Type="User">venkat</Value></Eq><Or><Eq><FieldRef Name="Editor" /><Value Type="User">amanda</Value></Eq><Eq><FieldRef Name="Editor" /><Value Type="User">arwen</Value></Eq></Or></Or></Or><Or><Eq><FieldRef Name="Editor" />
 <Value Type="User">matthew</Value></Eq><Or><Eq><FieldRef Name="Editor" /><Value Type="User">mcdonnel</Value></Eq><Eq><FieldRef Name="Editor" /><Value Type="User">ravi</Value></Eq></Or></Or></Or><Geq><FieldRef Name="Modified" /><Value Type="DateTime"><Today OffsetDays="-6" /></Value></Geq></And></Where>
"@ 


if($view) 
{ 
    #Write-Host $view.ViewQuery  -ForegroundColor Yellow
    #$view.Scope = 1 
    $view.ViewQuery = $query 
    $view.Update() 
    $srcContext.Load($view) 
    $srcContext.ExecuteQuery() 
    Write-Host "------------------------Updated---------------------" 
} 
else 
{ 
    Write-Host "NULL" 
} 

Write-Host "Done" 
