<#
  BioRadio page builder (Windows PowerShell 5.1+ or PowerShell 7).

  Run it after you add, remove or edit stations in index.html:
      powershell -ExecutionPolicy Bypass -File tools\build-pages.ps1

  It reads the station list from index.html and:
    - fills index.html with a plain-HTML copy of all stations and country links
      (search engines can read it even without running JavaScript)
    - writes one page per country, e.g. kenya/index.html, with its own title,
      description and structured data, so each country can rank on its own
    - writes sitemap.xml and robots.txt
#>
$ErrorActionPreference = 'Stop'
$SiteUrl = 'https://odhiambokelly.github.io/BioRadio/'
$Root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding $false
$indexPath = Join-Path $Root 'index.html'
$tpl = [IO.File]::ReadAllText($indexPath, $utf8)

$m = [regex]::Match($tpl, '<script id="stationData" type="application/json">([\s\S]*?)</script>')
if (-not $m.Success) { throw 'stationData block not found in index.html' }
$data = ($m.Groups[1].Value -replace '<\\/', '</') | ConvertFrom-Json

function Esc([string]$s) { [System.Net.WebUtility]::HtmlEncode($s) }
function Slug([string]$s) { ($s.ToLower() -replace '[^a-z0-9]+', '-').Trim('-') }
function JsonStr([string]$s) { ($s | ConvertTo-Json -Compress) -replace '</', '<\/' }
function SetBlock([string]$html, [string]$name, [string]$content) {
    $pattern = '<!--' + $name + '-->[\s\S]*?<!--/' + $name + '-->'
    if (-not [regex]::IsMatch($html, $pattern)) { throw "marker $name not found" }
    return [regex]::Replace($html, $pattern, { param($x) '<!--' + $name + '-->' + $content + '<!--/' + $name + '-->' })
}
function StationList($group, [bool]$withHeading) {
    $sb = New-Object System.Text.StringBuilder
    if ($withHeading) { [void]$sb.Append('<h2>' + (Esc $group.c) + ' radio stations</h2>') }
    [void]$sb.Append('<ul>')
    foreach ($s in $group.s) {
        $line = (Esc $s[0]) + ' – ' + (Esc $s[1]); if ($s[2]) { $line += ' (' + (Esc $s[2]) + ')' }
        [void]$sb.Append('<li>' + $line + '</li>')
    }
    [void]$sb.Append('</ul>')
    return $sb.ToString()
}

$total = 0; foreach ($g in $data) { $total += $g.s.Count }
$countryLinks = ($data | ForEach-Object { '<a href="' + (Slug $_.c) + '/">' + (Esc $_.c) + ' radio</a>' }) -join ''

# ---------- Home page: static copy of the list + links ----------
$allLists = ($data | ForEach-Object { StationList $_ $true }) -join ''
$homeHtml = SetBlock $tpl 'PRERENDER' $allLists
$homeHtml = SetBlock $homeHtml 'COUNTRYLINKS' $countryLinks
[IO.File]::WriteAllText($indexPath, $homeHtml, $utf8)

# ---------- One page per country ----------
$today = (Get-Date).ToString('yyyy-MM-dd')
$urls = New-Object System.Collections.Generic.List[string]
$urls.Add($SiteUrl)
foreach ($g in $data) {
    $slug = Slug $g.c
    $n = $g.s.Count
    $url = $SiteUrl + $slug + '/'
    $names = @($g.s | Select-Object -First 5 | ForEach-Object { $_[0] })
    $namesTxt = ($names -join ', ')
    $title = "$($g.c) Radio Stations – Listen Live Online Free | BioRadio"
    $desc = "Listen to $n free live $($g.c) radio stations online: $namesTxt" + $(if ($n -gt 5) { ' and more' } else { '' }) + '. No sign-up, works on 2G, 3G and 4G.'
    $items = @()
    $pos = 1
    foreach ($s in $g.s) {
        $items += '{"@type":"ListItem","position":' + $pos + ',"item":{"@type":"RadioStation","name":' + (JsonStr $s[0]) + ',"genre":' + (JsonStr $s[1]) + ',"areaServed":{"@type":"Country","name":' + (JsonStr $g.c) + '}}}'
        $pos++
    }
    $ld = '{"@context":"https://schema.org","@graph":[' +
          '{"@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"BioRadio","item":"' + $SiteUrl + '"},{"@type":"ListItem","position":2,"name":' + (JsonStr "$($g.c) radio") + ',"item":"' + $url + '"}]},' +
          '{"@type":"ItemList","name":' + (JsonStr "$($g.c) radio stations") + ',"numberOfItems":' + $n + ',"itemListElement":[' + ($items -join ',') + ']}]}'
    $seo = "`n    <title>$(Esc $title)</title>`n" +
           "    <meta name=`"description`" content=`"$(Esc $desc)`">`n" +
           "    <link rel=`"canonical`" href=`"$url`">`n" +
           "    <meta property=`"og:type`" content=`"website`">`n" +
           "    <meta property=`"og:site_name`" content=`"BioRadio`">`n" +
           "    <meta property=`"og:title`" content=`"$(Esc "$($g.c) radio stations – listen live, free")`">`n" +
           "    <meta property=`"og:description`" content=`"$(Esc $desc)`">`n" +
           "    <meta property=`"og:url`" content=`"$url`">`n" +
           "    <meta property=`"og:image`" content=`"${SiteUrl}og-image.png`">`n" +
           "    <meta name=`"twitter:card`" content=`"summary_large_image`">`n" +
           "    <meta name=`"twitter:image`" content=`"${SiteUrl}og-image.png`">`n" +
           "    <script type=`"application/ld+json`">$ld</script>`n    "
    $base = '<base href="../"><script>window.BIORADIO_FOCUS=' + (JsonStr $g.c) + ';</script>'
    $hero = "`n            <h1><span>$(Esc $g.c)</span> radio stations – live &amp; free</h1>`n" +
            "            <p class=`"sub`">Listen to $n $(Esc $g.c) radio stations online, plus 25+ more countries. No sign-up, made for 2G, 3G and 4G.</p>`n            "
    $about = "`n            <h2>About $(Esc $g.c) radio on BioRadio</h2>`n" +
             "            <p>Listen live to $(Esc $g.c) radio stations including $(Esc $namesTxt). Every stream is checked before it is listed. BioRadio also has $total free English radio stations from $($data.Count) countries, and installs as an app on Android and PC.</p>`n            "
    $page = SetBlock $homeHtml 'SEO' $seo
    $page = SetBlock $page 'BASE' $base
    $page = SetBlock $page 'HERO' $hero
    $page = SetBlock $page 'ABOUT' $about
    $page = SetBlock $page 'PRERENDER' (StationList $g $true)
    $dir = Join-Path $Root $slug
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory $dir | Out-Null }
    [IO.File]::WriteAllText((Join-Path $dir 'index.html'), $page, $utf8)
    $urls.Add($url)
}

# ---------- sitemap.xml + robots.txt ----------
$sm = '<?xml version="1.0" encoding="UTF-8"?>' + "`n" + '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' + "`n"
foreach ($u in $urls) { $sm += "  <url><loc>$u</loc><lastmod>$today</lastmod><changefreq>weekly</changefreq><priority>$(if ($u -eq $SiteUrl) { '1.0' } else { '0.8' })</priority></url>`n" }
$sm += '</urlset>' + "`n"
[IO.File]::WriteAllText((Join-Path $Root 'sitemap.xml'), $sm, $utf8)
[IO.File]::WriteAllText((Join-Path $Root 'robots.txt'), "User-agent: *`nAllow: /`n`nSitemap: ${SiteUrl}sitemap.xml`n", $utf8)

"Built home + $($data.Count) country pages, $total stations, sitemap with $($urls.Count) URLs."
