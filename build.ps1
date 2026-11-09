param()
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$Domain = "https://www.bayluxappliance.com"

function Set-ActiveNav([string]$html, [string]$activeNav) {
    if (-not $activeNav) { return $html }
    $navMatch = [regex]::Match($html, '(?s)(<nav.*?</nav>)')
    if (-not $navMatch.Success) { return $html }
    $navBlock = $navMatch.Groups[1].Value
    $navBlockNew = $navBlock -replace ([regex]::Escape("href=`"$activeNav`"")), ("href=`"$activeNav`" class=`"active`"")
    return $html.Substring(0, $navMatch.Index) + $navBlockNew + $html.Substring($navMatch.Index + $navMatch.Length)
}

function Convert-Paths([string]$html, [string]$base, [string]$rootHref) {
    $html = $html -replace 'href="/"', ("href=`"$rootHref`"")
    $html = [regex]::Replace($html, 'href="/([^"]+)"', { param($m) "href=`"$base$($m.Groups[1].Value)`"" })
    $html = [regex]::Replace($html, 'src="/([^"]+)"', { param($m) "src=`"$base$($m.Groups[1].Value)`"" })
    return $html
}

function Get-HomeJsonLd() {
@"
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"Organization","name":"BayLuxAppliance","url":"$Domain/","logo":"$Domain/images/logo.svg","areaServed":["Santa Clara, CA","San Jose, CA","Sunnyvale, CA","Cupertino, CA","Campbell, CA","Los Gatos, CA","Saratoga, CA"]}
</script>
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"WebPage","name":"Appliance Repair Santa Clara CA: Same-Day Service 2026","url":"$Domain/","description":"Book licensed Santa Clara appliance repair today. Same-day service, flat-rate pricing, parts for every major brand.","inLanguage":"en-US","isPartOf":{"@type":"WebSite","name":"BayLuxAppliance","url":"$Domain/"}}
</script>
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[
{"@type":"Question","name":"Is DIY appliance repair a good idea in Santa Clara?","acceptedAnswer":{"@type":"Answer","text":"DIY repair can void a manufacturer warranty and is not always covered by homeowner insurance. It works for minor fixes only, such as replacing a washing machine lid switch, but gas and electrical appliance faults carry safety risk best left to a licensed technician."}},
{"@type":"Question","name":"Should I choose OEM or generic parts for my appliance repair?","acceptedAnswer":{"@type":"Answer","text":"OEM parts cost more but preserve the manufacturer warranty on brands like GE, Samsung, and Sub-Zero. Generic third-party parts cost less upfront but carry inconsistent warranty coverage and can void the original manufacturer warranty."}},
{"@type":"Question","name":"Should I repair or replace my appliance?","acceptedAnswer":{"@type":"Answer","text":"Replace the appliance once repair cost reaches roughly 50 percent of a new unit's price. Average lifespans guide this decision: washing machine 11 years, clothes dryer 14 years, refrigerator 15 years, electric stove 15 years, dishwasher 10 years, freezer 15 years."}},
{"@type":"Question","name":"What does the BayLuxAppliance labor warranty cover?","acceptedAnswer":{"@type":"Answer","text":"The labor warranty covers both parts and labor on the completed repair. If the same fault recurs within the warranty period, BayLuxAppliance returns at no additional labor charge."}},
{"@type":"Question","name":"What counts as an emergency appliance repair?","acceptedAnswer":{"@type":"Answer","text":"Refrigerator or freezer cooling failure, an actively flooding washer, and a gas oven ignition fault all qualify for emergency same-day dispatch ahead of standard scheduling."}},
{"@type":"Question","name":"Do you offer faster scheduling for commercial customers?","acceptedAnswer":{"@type":"Answer","text":"Yes. Commercial appliance failures receive priority dispatch over standard residential scheduling, since a failed unit in a restaurant or rental property directly halts business operations."}}
]}
</script>
"@
}

function Get-BasicJsonLd([string]$title, [string]$url, [string]$desc) {
@"
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"Organization","name":"BayLuxAppliance","url":"$Domain/","logo":"$Domain/images/logo.svg","areaServed":["Santa Clara, CA","San Jose, CA","Sunnyvale, CA","Cupertino, CA","Campbell, CA","Los Gatos, CA","Saratoga, CA"]}
</script>
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"WebPage","name":"$title","url":"$url","description":"$desc","inLanguage":"en-US","isPartOf":{"@type":"WebSite","name":"BayLuxAppliance","url":"$Domain/"}}
</script>
"@
}

function Build-Page {
    param(
        [string]$ContentFile, [string]$OutFile, [string]$Title, [string]$Description,
        [string]$Canonical, [string]$ActiveNav, [int]$Depth, [string]$JsonLd
    )
    $base = if ($Depth -eq 0) { "" } else { "../" }
    $rootHref = if ($Depth -eq 0) { "/" } else { "../" }

    $header = Get-Content "components/header.html" -Raw
    $footer = Get-Content "components/footer.html" -Raw
    $content = Get-Content $ContentFile -Raw

    $header = Set-ActiveNav $header $ActiveNav
    $header = Convert-Paths $header $base $rootHref
    $footer = Convert-Paths $footer $base $rootHref
    $content = Convert-Paths $content $base $rootHref

    $html = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$Title</title>
<meta name="description" content="$Description">
<link rel="canonical" href="$Canonical">
<meta property="og:type" content="website">
<meta property="og:title" content="$Title">
<meta property="og:description" content="$Description">
<meta property="og:url" content="$Canonical">
<link rel="icon" type="image/svg+xml" href="${base}images/favicon.svg">
<link rel="stylesheet" href="${base}css/global.css">
<link rel="stylesheet" href="${base}css/ranking.css">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
$JsonLd
</head>
<body>
$header
<main>
$content
</main>
$footer
<script src="${base}js/nav.js"></script>
</body>
</html>
"@
    $fullPath = Join-Path (Get-Location) $OutFile
    [System.IO.File]::WriteAllText($fullPath, $html, (New-Object System.Text.UTF8Encoding($false)))
    Write-Output "Built: $OutFile"
}

New-Item -ItemType Directory -Force -Path "about","contact","editorial-policy","cookie-policy" | Out-Null

Build-Page -ContentFile "content/main-ranking.html" -OutFile "index.html" `
    -Title "Santa Clara Appliance Repair | Flat-Rate, Same-Day Techs" `
    -Description "Book licensed Santa Clara appliance repair today. Same-day service, flat-rate pricing, parts for every major brand." `
    -Canonical "$Domain/" -ActiveNav "/" -Depth 0 -JsonLd (Get-HomeJsonLd)

Build-Page -ContentFile "content/about.html" -OutFile "about/index.html" `
    -Title "About BayLuxAppliance | Santa Clara Appliance Repair" `
    -Description "How BayLuxAppliance sources pricing, licensing, and brand data for its Santa Clara appliance repair content." `
    -Canonical "$Domain/about/" -ActiveNav "/about/" -Depth 1 `
    -JsonLd (Get-BasicJsonLd "About BayLuxAppliance" "$Domain/about/" "How BayLuxAppliance sources pricing, licensing, and brand data for its Santa Clara appliance repair content.")

Build-Page -ContentFile "content/contact.html" -OutFile "contact/index.html" `
    -Title "Contact BayLuxAppliance | Santa Clara, CA" `
    -Description "Reach BayLuxAppliance to schedule appliance repair in Santa Clara, CA and nearby cities." `
    -Canonical "$Domain/contact/" -ActiveNav "/contact/" -Depth 1 `
    -JsonLd (Get-BasicJsonLd "Contact BayLuxAppliance" "$Domain/contact/" "Reach BayLuxAppliance to schedule appliance repair in Santa Clara, CA and nearby cities.")

Build-Page -ContentFile "content/editorial-policy.html" -OutFile "editorial-policy/index.html" `
    -Title "Editorial Policy | BayLuxAppliance" `
    -Description "How BayLuxAppliance sources, verifies, and updates appliance repair pricing and licensing information." `
    -Canonical "$Domain/editorial-policy/" -ActiveNav "/editorial-policy/" -Depth 1 `
    -JsonLd (Get-BasicJsonLd "Editorial Policy" "$Domain/editorial-policy/" "How BayLuxAppliance sources, verifies, and updates appliance repair pricing and licensing information.")

Build-Page -ContentFile "content/cookie-policy.html" -OutFile "cookie-policy/index.html" `
    -Title "Cookie Policy | BayLuxAppliance" `
    -Description "How BayLuxAppliance uses browser cookies and how to manage your cookie preferences." `
    -Canonical "$Domain/cookie-policy/" -ActiveNav "/cookie-policy/" -Depth 1 `
    -JsonLd (Get-BasicJsonLd "Cookie Policy" "$Domain/cookie-policy/" "How BayLuxAppliance uses browser cookies and how to manage your cookie preferences.")

Write-Output "Build complete."
