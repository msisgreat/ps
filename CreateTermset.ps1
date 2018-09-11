Add-Type -Path ".\CSOM\Microsoft.SharePoint.Client.dll"
Add-Type -Path ".\CSOM\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path ".\CSOM\Microsoft.SharePoint.Client.Taxonomy.dll"

$now=Get-Date -format "dd-MMM-yy,HH:mm:ss"
Write-Host "Script Start : '$($now)'" -ForegroundColor Yellow

$username = "user name"
$password = "<PWD>"
$srcUrl = "SITE URL"
$xmlFilePath = "C:\Github\msisgreat\ps\ps\sample\CountriesTerm.xml" # change this to xml path with the termset defined

$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword)

function CreateTerm($context, $termSet, $label, $lcid, $termXmlData)
{
  $terms = $termSet.Terms
  $context.Load($terms)
  $context.ExecuteQuery()
  $term = $terms | Where-Object {$_.Name -eq $label}  
  if($term)
  {
    Write-Host "Term" $label   "already exists." -foregroundcolor Blue
    $termXmlData.Term | ForEach-Object { CreateTerm $context $term $_.Name $lcid $_ }
  }
  elseif($label)
  {
    Write-Host "Creating term " $label -foregroundcolor yellow
    $term = $termSet.CreateTerm($label, $lcid, [System.Guid]::NewGuid())
    try
    {
      $context.ExecuteQuery()
      Write-Host "Term" $label "Created successfully" -foregroundcolor Green
      $termXmlData.Term | ForEach-Object { CreateTerm $context $term $_.Name $lcid $_ }
    }
    catch
    {
      Write-Host "Error while creating Term" $label $_.Exception.Message -foregroundcolor Red
      return
    }  
  }
}

function CreateTermSet($context, $group, $termSetXml, $lcid)
{
  $termSets = $group.TermSets
  $context.Load($termSets)
  $context.ExecuteQuery()
  $termSet = $termSets | Where-Object {$_.Name -eq $termSetXml.Name}  

  if($termSet)
  {
  Write-Host "Termset" $termSetXml.Name   "already exists."   -foregroundcolor Blue
  $termSet = $group.TermSets.GetByName($termSetXml.Name)
  $context.Load($termSet)
  $context.ExecuteQuery()
  }
  else
  {
    Write-Host "Creating term set" $termSetXml.Name -foregroundcolor yellow
    $termSet = $group.CreateTermSet($termSetXml.Name, [System.Guid]::NewGuid(), $lcid)
    try
    {
      $context.ExecuteQuery()
      Write-Host "Term set " $termSetXml.Name "Created successfully" -foregroundcolor Green
    }
    catch
    {
      Write-Host "Error while creating Term set" $termSetXml.Name $_.Exception.Message -foregroundcolor Red
      return
    }  
  }
  $termSetXml.Term | ForEach-Object { CreateTerm $context $termSet $_.Name $lcid $_ }
}

function CreateTermSet($context, $group, $termSetXml, $lcid)
{
  $termSets = $group.TermSets
  $context.Load($termSets)
  $context.ExecuteQuery()
  $termSet = $termSets | Where-Object {$_.Name -eq $termSetXml.Name}  

  if($termSet)
  {
  Write-Host "Termset" $termSetXml.Name   "already exists."   -foregroundcolor Cyan
  $termSet = $group.TermSets.GetByName($termSetXml.Name)
  $context.Load($termSet)
  $context.ExecuteQuery()
  }
  else
  {
    Write-Host "Creating term set" $termSetXml.Name -foregroundcolor yellow
    $termSet = $group.CreateTermSet($termSetXml.Name, [System.Guid]::NewGuid(), $lcid)
    try
    {
      $context.ExecuteQuery()
      Write-Host "Term set " $termSetXml.Name "Created successfully" -foregroundcolor Green
    }
    catch
    {
      Write-Host "Error while creating Term set" $termSetXml.Name $_.Exception.Message -foregroundcolor Red
      return
    }  
  }
  $termSetXml.Term | ForEach-Object { CreateTerm $context $termSet $_.Name $lcid $_ }
}


function Get-TermStoreInfo 
 { 
   Write-Host "Loading taxonomy session" -foregroundcolor yellow 
   $session = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($context) 
   $session.UpdateCache(); 
   $context.Load($session) 
   $context.ExecuteQuery() 
   Write-Host "Loading term stores" -foregroundcolor yellow 
   $termStores = $session.TermStores 
   $context.Load($termStores) 
   try 
   { 
     $context.ExecuteQuery() 
     $termStore = $termStores[0] 
     $context.Load($termStore) 
     Write-Host "Term store with the following id is loaded:" $termStore.Id -foregroundcolor Green 
   } 
   catch 
   { 
     Write-Host "Error detail while getting term store id" $_.Exception.Message -foregroundcolor Red 
     return 
   }
   return $termStore 
 } 

 function CreateMetadata($context)
{
       
    Write-Host "Loading the terset xml..." -foregroundcolor Green
    [xml]$xmlContent = (Get-Content $xmlFilePath)
    if (-not $xmlContent)
    {
      Write-Host "Error loading the xml." -foregroundcolor Red
      return
    }  
    $termStore = Get-TermStoreInfo $context  
    Write-Host "Create Taxonomy group if it is not available" -foregroundcolor yellow
    $sitecollectiontaxonomyGroup = $termStore.GetSiteCollectionGroup($context.Site,$true)
    $context.Load($sitecollectiontaxonomyGroup)
    try
    {
      $context.ExecuteQuery()
      Write-Host "Site collection $url taxonomy group  "$sitecollectiontaxonomyGroup.Name" created or retrived successfully " -foregroundcolor Green
    }
    catch
    {
      Write-Host "Error while creating or getting site collection $url taxonomy group" $_.Exception.Message -foregroundcolor Red
      return
    }

    $xmlContent.TermSets.TermSet |
    ForEach-Object { CreateTermSet $context $sitecollectiontaxonomyGroup $_ $termStore.DefaultLanguage }
} 

### The script starts here to run ####
Write-Host "Authenticating ..." -ForegroundColor White
$context = New-Object Microsoft.SharePoint.Client.ClientContext($srcUrl) 
$context.Credentials = $credentials
$web = $context.Web
$site = $context.Site 
$context.Load($web)
$context.Load($site)
try {
    $context.ExecuteQuery()
}
catch {
    Write-Host "Error" + $_.Exception.Message -ForegroundColor Red
    exit
}

Write-Host "Connected to the web..." -ForegroundColor Cyan
#Provision Site collection taxonomy group, termset and terms based on SiteCollectionTermsets.xml configuration file
Write-Host "Provisioning Site collection terms started" -foregroundcolor yellow
CreateMetadata ($context)
Write-Host "Provisioning Site collection terms Completed" -foregroundcolor green
$context.dispose()

