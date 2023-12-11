$site = "https://giac.org"

# see if sitemap.xml exists:

$response = try { 
    (invoke-webrequest -uri ($site + '/sitemap.xml') -ErrorAction Stop).BaseResponse
} catch [System.Net.WebException] { 
    Write-Verbose "An exception was caught: $($_.Exception.Message)"
    $_.Exception.Response 
} 

#then convert the status code enum to int by doing this
$SMstatusCodeInt = [int]$response.BaseResponse.StatusCode

$response = try { 
    (invoke-webrequest -uri ($site + '/sitemap_index.xml') -ErrorAction Stop).BaseResponse
} catch [System.Net.WebException] { 
    Write-Verbose "An exception was caught: $($_.Exception.Message)"
    $_.Exception.Response 
} 

#then convert the status code enum to int by doing this
$SMIstatusCodeInt = [int]$response.BaseResponse.StatusCode

# yes, this next block could be expressed more elegantly, but it would be less readable
# and I want you to be able to read it

# if sitemap.xml isn't there, try sitemap_index.xml
if ($SMstatuscodeint -eq 200) {
    $sitemap = invoke-webrequest -uri ($site + '/sitemap.xml')
    # parse out just the links, the values inside the "url" xml tags
    $sitemaplinks = ([xml] $sitemap).urlset.url.loc
    }

if ($SMIstatuscodeint -eq 200) {
    #first, collect the parent sitemap_index.xml, this only contains links to xml files:
    $site="https://companyname.com"
    $sitemap_parent =  invoke-webrequest -uri ($site + '/sitemap_index.xml')
    $xml_parent = ([xml]$sitemap_parent).sitemapindex.sitemap.loc
    
    $temp = @()
    foreach ($x in $xml_parent) {
        $s = invoke-webrequest -uri $x
        $temp += ([xml] $s).urlset.url
        }

    $sitemaplinks = $temp | sort | uniq
    }

# get the actual site links, exported from burp or your favourite spidering tool:
$sitelinks = get-content c:\work\spidered-links-exported-from-burp.txt

# remove trailing "/" chars from both lists

$smlist = @()
foreach ($sml in $sitemaplinks ) {
   $l = $sml.length
   if($sml.substring($l-1,1) -eq "/" ) { $sml = $sml.substring(0,$l-1) }
   $smlist += $sml
   }

$slist = @()
foreach ($sl in $sitelinks ) {
   $l = $sl.length
   if($sl.substring($l-1,1) -eq "/" ) { $sl = $sl.substring(0,$l-1) }
   $slist += $sl
   }

$diff = $smlist | ?{$slist -notcontains $_}

# this list is your target.  Items that are in the sitemap files but are not navigable from the site.

$diff

    
