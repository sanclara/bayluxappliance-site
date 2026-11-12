#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

DOMAIN="https://www.bayluxappliance.com"

# ---------- JSON-LD builders ----------

make_basic_jsonld() {
  local title="$1" url="$2" desc="$3"
  local f
  f=$(mktemp)
  cat > "$f" <<JSONLD
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"Organization","name":"BayLuxAppliance","url":"${DOMAIN}/","logo":"${DOMAIN}/images/logo.svg","areaServed":["Santa Clara, CA","San Jose, CA","Sunnyvale, CA","Cupertino, CA","Campbell, CA","Los Gatos, CA","Saratoga, CA"]}
</script>
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"WebPage","name":"${title}","url":"${url}","description":"${desc}","inLanguage":"en-US","isPartOf":{"@type":"WebSite","name":"BayLuxAppliance","url":"${DOMAIN}/"}}
</script>
JSONLD
  echo "$f"
}

make_home_jsonld() {
  local f
  f=$(mktemp)
  cat > "$f" <<JSONLD
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"Organization","name":"BayLuxAppliance","url":"${DOMAIN}/","logo":"${DOMAIN}/images/logo.svg","areaServed":["Santa Clara, CA","San Jose, CA","Sunnyvale, CA","Cupertino, CA","Campbell, CA","Los Gatos, CA","Saratoga, CA"]}
</script>
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"WebPage","name":"Appliance Repair Santa Clara CA: Same-Day Service 2026","url":"${DOMAIN}/","description":"Book licensed Santa Clara appliance repair today. Same-day service, flat-rate pricing, parts for every major brand.","inLanguage":"en-US","isPartOf":{"@type":"WebSite","name":"BayLuxAppliance","url":"${DOMAIN}/"}}
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
JSONLD
  echo "$f"
}

# ---------- page assembler ----------

build_page() {
  local content_file=$1
  local out_file=$2
  local title=$3
  local description=$4
  local canonical=$5
  local active_nav=$6
  local depth=$7
  local jsonld_file=$8

  local base root_href
  if [ "$depth" = "0" ]; then base=""; root_href="/"; else base="../"; root_href="../"; fi

  local tmp_header tmp_footer tmp_content
  tmp_header=$(mktemp)
  tmp_footer=$(mktemp)
  tmp_content=$(mktemp)

  sed \
    -e "/<nav/,/<\/nav>/ s|href=\"$active_nav\"|href=\"$active_nav\" class=\"active\"|" \
    -e "s|href=\"/\"|href=\"${root_href}\"|g" \
    -e "s|href=\"/\([^\"]\+\)\"|href=\"${base}\1\"|g" \
    -e "s|src=\"/\([^\"]\+\)\"|src=\"${base}\1\"|g" \
    components/header.html > "$tmp_header"

  sed \
    -e "s|href=\"/\"|href=\"${root_href}\"|g" \
    -e "s|href=\"/\([^\"]\+\)\"|href=\"${base}\1\"|g" \
    -e "s|src=\"/\([^\"]\+\)\"|src=\"${base}\1\"|g" \
    components/footer.html > "$tmp_footer"

  sed \
    -e "s|href=\"/\"|href=\"${root_href}\"|g" \
    -e "s|href=\"/\([^\"]\+\)\"|href=\"${base}\1\"|g" \
    -e "s|src=\"/\([^\"]\+\)\"|src=\"${base}\1\"|g" \
    "$content_file" > "$tmp_content"

  {
    echo '<!doctype html>'
    echo '<html lang="en">'
    echo '<head>'
    echo '<script async src="https://www.googletagmanager.com/gtm.js?id=GTM-T8V455DT"></script>'
    echo '<script>'
    echo '  window.dataLayer = window.dataLayer || [];'
    echo '  function gtag(){dataLayer.push(arguments);}'
    echo "  gtag('js', new Date());"
    echo '</script>'
    echo '<meta charset="utf-8">'
    echo '<meta name="viewport" content="width=device-width, initial-scale=1">'
    echo "<title>${title}</title>"
    echo "<meta name=\"description\" content=\"${description}\">"
    echo "<link rel=\"canonical\" href=\"${canonical}\">"
    echo '<meta property="og:type" content="website">'
    echo "<meta property=\"og:title\" content=\"${title}\">"
    echo "<meta property=\"og:description\" content=\"${description}\">"
    echo "<meta property=\"og:url\" content=\"${canonical}\">"
    echo "<link rel=\"icon\" type=\"image/svg+xml\" href=\"${base}images/favicon.svg\">"
    echo "<link rel=\"stylesheet\" href=\"${base}css/global.css\">"
    echo "<link rel=\"stylesheet\" href=\"${base}css/ranking.css\">"
    echo '<link rel="preconnect" href="https://fonts.googleapis.com">'
    echo '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">'
    if [ -n "$jsonld_file" ]; then cat "$jsonld_file"; fi
    echo '</head>'
    echo '<body>'
    cat "$tmp_header"
    echo '<main>'
    cat "$tmp_content"
    echo '</main>'
    cat "$tmp_footer"
    echo "<script src=\"${base}js/nav.js\"></script>"
    echo '</body>'
    echo '</html>'
  } > "$out_file"

  rm -f "$tmp_header" "$tmp_footer" "$tmp_content"
}

# ---------- build each page ----------

JSONLD_HOME=$(make_home_jsonld)
build_page content/main-ranking.html index.html \
  "Santa Clara Appliance Repair | Flat-Rate, Same-Day Techs" \
  "Book licensed Santa Clara appliance repair today. Same-day service, flat-rate pricing, parts for every major brand." \
  "${DOMAIN}/" "/" "0" "$JSONLD_HOME"
rm -f "$JSONLD_HOME"

JSONLD_ABOUT=$(make_basic_jsonld "About BayLuxAppliance" "${DOMAIN}/about/" "How BayLuxAppliance sources pricing, licensing, and brand data for its Santa Clara appliance repair content.")
build_page content/about.html about/index.html \
  "About BayLuxAppliance | Santa Clara Appliance Repair" \
  "How BayLuxAppliance sources pricing, licensing, and brand data for its Santa Clara appliance repair content." \
  "${DOMAIN}/about/" "/about/" "1" "$JSONLD_ABOUT"
rm -f "$JSONLD_ABOUT"

JSONLD_CONTACT=$(make_basic_jsonld "Contact BayLuxAppliance" "${DOMAIN}/contact/" "Reach BayLuxAppliance to schedule appliance repair in Santa Clara, CA and nearby cities.")
build_page content/contact.html contact/index.html \
  "Contact BayLuxAppliance | Santa Clara, CA" \
  "Reach BayLuxAppliance to schedule appliance repair in Santa Clara, CA and nearby cities." \
  "${DOMAIN}/contact/" "/contact/" "1" "$JSONLD_CONTACT"
rm -f "$JSONLD_CONTACT"

JSONLD_EDITORIAL=$(make_basic_jsonld "Editorial Policy" "${DOMAIN}/editorial-policy/" "How BayLuxAppliance sources, verifies, and updates appliance repair pricing and licensing information.")
build_page content/editorial-policy.html editorial-policy/index.html \
  "Editorial Policy | BayLuxAppliance" \
  "How BayLuxAppliance sources, verifies, and updates appliance repair pricing and licensing information." \
  "${DOMAIN}/editorial-policy/" "/editorial-policy/" "1" "$JSONLD_EDITORIAL"
rm -f "$JSONLD_EDITORIAL"

JSONLD_COOKIE=$(make_basic_jsonld "Cookie Policy" "${DOMAIN}/cookie-policy/" "How BayLuxAppliance uses browser cookies and how to manage your cookie preferences.")
build_page content/cookie-policy.html cookie-policy/index.html \
  "Cookie Policy | BayLuxAppliance" \
  "How BayLuxAppliance uses browser cookies and how to manage your cookie preferences." \
  "${DOMAIN}/cookie-policy/" "/cookie-policy/" "1" "$JSONLD_COOKIE"
rm -f "$JSONLD_COOKIE"

echo "Build complete."
