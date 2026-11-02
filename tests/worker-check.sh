#!/bin/bash
# Check the download Worker from outside: tests/worker-check.sh BASE_URL
# (https://swarf-os.<subdomain>.workers.dev, or http://localhost:8787 for wrangler dev).
# Reads the page, follows its ISO and SHA256SUMS links, and checks HEAD, Range (206) and 404.
# Downloads only the SHA256SUMS file and 1 KiB of the ISO. Prints OK or the failed checks.
set -uo pipefail
base=${1%/}
fail=0
bad() { echo "FAIL: $*"; fail=1; }

html=$(curl -fsS "$base/") || { echo "FAIL: GET / did not answer"; exit 1; }
grep -q 'id="gate"' <<<"$html" || bad "no word form on the page"
grep -q '=== "fraws"' <<<"$html" || bad "the visual word is not the expected one"
iso=$(grep -o 'href="/[0-9]\{8\}-[0-9]\{4\}/[^"]*\.iso"' <<<"$html" | head -1 | cut -d'"' -f2)
[ -n "$iso" ] || { echo "FAIL: no ISO link on the page"; exit 1; }
dir=${iso%/*}
echo "page lists $iso"

curl -fsS "$base/robots.txt" | grep -q 'Disallow: /' || bad "robots.txt"

head=$(curl -fsSI "$base$iso" | tr -d '\r') || bad "HEAD $iso"
size=$(awk 'tolower($1)=="content-length:"{print $2}' <<<"$head")
[ "${size:-0}" -gt 0 ] || bad "HEAD gives no size"
grep -qi '^accept-ranges: bytes' <<<"$head" || bad "no Accept-Ranges"
grep -qi '^content-disposition: attachment' <<<"$head" || bad "no Content-Disposition"

code=$(curl -sS -o /dev/null -w '%{http_code} %{size_download}' -r 0-1023 "$base$iso")
[ "$code" = "206 1024" ] || bad "Range 0-1023 gave '$code', expected '206 1024'"
cr=$(curl -sS -D - -o /dev/null -r 0-1023 "$base$iso" | tr -d '\r' | awk 'tolower($1)=="content-range:"{print $2, $3}')
[ "$cr" = "bytes 0-1023/$size" ] || bad "Content-Range '$cr', expected 'bytes 0-1023/$size'"

sums=$(curl -fsS "$base$dir/SHA256SUMS") || bad "GET SHA256SUMS"
grep -q " ${iso##*/}\$" <<<"$sums" || bad "SHA256SUMS does not name ${iso##*/}"
[ "$(curl -s -o /dev/null -w '%{http_code}' -I "$base$dir/SHA256SUMS.bundle")" = 200 ] || bad "no SHA256SUMS.bundle"

for p in /nothing "$dir/missing.iso" /../etc/passwd; do
  c=$(curl -s -o /dev/null -w '%{http_code}' "$base$p")
  [ "$c" = 404 ] || bad "GET $p gave $c, expected 404"
done
c=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$base/")
[ "$c" = 405 ] || bad "POST / gave $c, expected 405"

[ $fail = 0 ] && echo "OK $base ($size bytes ISO)"
exit $fail
