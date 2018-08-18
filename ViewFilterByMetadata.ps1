Add-Type -Path ".\CSOM\Microsoft.SharePoint.Client.dll"
Add-Type -Path ".\CSOM\Microsoft.SharePoint.Client.Runtime.dll"


$username = "<USERNAME>" 
$password = "<PWD>" 
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force 
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword) 
Write-Host "Connecting to site ..." 
$srcUrl = "<SITE URL>" 

$srcContext = New-Object Microsoft.SharePoint.Client.ClientContext($srcUrl)  
$srcContext.Credentials = $credentials 
$srcWeb = $srcContext.Web 
$srcList = $srcWeb.Lists.GetByTitle("Documents") 
$view = $srcList.Views.GetByTitle("O365 Files")


$srcContext.Load($srcWeb) 
$srcContext.Load($srcList) 
$srcContext.Load($view) 
$srcContext.ExecuteQuery() 
Write-Host "Connected successfully" 


$query =  @" 
  <OrderBy><FieldRef Name="Modified" Ascending="FALSE" /></OrderBy>
  <Where><And><Geq><FieldRef Name="Modified" /><Value Type="DateTime"><Today OffsetDays="-30" /></Value></Geq>
  <In>
  <FieldRef LookupId="TRUE" Name="Category" />
  <Values>
  <Value Type="Integer">37</Value>
  <Value Type="Integer">40</Value>
  <Value Type="Integer">53</Value>
  <Value Type="Integer">54</Value>
  <Value Type="Integer">55</Value>
  <Value Type="Integer">56</Value>
<Value Type="Integer">57</Value>
  </Values>
  </In>
  </And></Where>
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
