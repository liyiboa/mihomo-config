#!/data/data/com.termux/files/usr/bin/bash
set -e

REPO_DIR="/data/data/com.termux/files/home/downloads"
RULE_DIR="$REPO_DIR/rule_provider"
GH="https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash"
MIN_SIZE=100

urls() {
  cat <<'EOF'
Telegram.list|${GH}/Telegram/Telegram.list
TikTok.list|${GH}/TikTok/TikTok.list
AI.list|${GH}/OpenAI/OpenAI.list
AppleAccount.list|${GH}/Apple/Apple.list
AppStore.list|${GH}/AppStore/AppStore.list
GitHub.list|${GH}/GitHub/GitHub.list
Netflix.list|${GH}/Netflix/Netflix.list
YouTube.list|${GH}/YouTube/YouTube.list
Disney.list|${GH}/Disney/Disney.list
Twitter.list|${GH}/Twitter/Twitter.list
Facebook.list|${GH}/Facebook/Facebook.list
Instagram.list|${GH}/Instagram/Instagram.list
Spotify.list|${GH}/Spotify/Spotify.list
Google.list|${GH}/Google/Google.list
OneDrive.list|${GH}/OneDrive/OneDrive.list
Steam.list|https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/refs/heads/master/Clash/Ruleset/Steam.list
LAN_SPLITTER.list|https://fastly.jsdelivr.net/gh/fmz200/wool_scripts@main/Loon/rule/LAN.list
mihomo.mrs|https://fastly.jsdelivr.net/gh/privacy-protection-tools/anti-ad.github.io@master/docs/mihomo.mrs
EOF
}

ok=0; fail=0
mkdir -p "$RULE_DIR"

echo "=== Downloading rules ==="
while IFS='|' read -r filename url; do
  eval "url=$url"
  tmpfile=$(mktemp)
  set +e
  http_code=$(curl -sL --connect-timeout 15 --max-time 30 \
    -w "%{http_code}" -o "$tmpfile" "$url" 2>/dev/null)
  size=$(wc -c < "$tmpfile" 2>/dev/null || echo 0)
  set -e
  if [ "$http_code" = "200" ] && [ "$size" -gt "$MIN_SIZE" ]; then
    cp "$tmpfile" "$RULE_DIR/$filename"
    echo "  OK  $filename ($size bytes)"
    ok=$((ok+1))
  else
    echo " FAIL $filename (HTTP $http_code, size $size)"
    fail=$((fail+1))
  fi
  rm -f "$tmpfile"
done < <(urls)

echo ""
echo "=== $ok OK, $fail failed ==="

cd "$REPO_DIR"
if git diff --quiet && git diff --cached --quiet; then
  echo "No changes, skip."
  exit 0
fi

git add -A
git commit -m "Auto update rule files $(date '+%Y-%m-%d %H:%M')"
git push
echo "Pushed to GitHub."
