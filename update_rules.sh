#!/data/data/com.termux/files/usr/bin/bash
set -e

REPO_DIR="/data/data/com.termux/files/home/downloads"
PROXY="http://127.0.0.1:7890"
RULE_DIR="$REPO_DIR/rule_provider"
MIN_SIZE=100

source_urls() {
  cat <<'EOF'
Telegram.list|https://rule.kelee.one/Loon/Telegram.lsr
TikTok.list|https://kelee.one/Tool/Loon/Lsr/TikTok.lsr
AI.list|https://kelee.one/Tool/Loon/Lsr/AI.lsr
AppleAccount.list|https://kelee.one/Tool/Loon/Lsr/AppleAccount.lsr
AppStore.list|https://kelee.one/Tool/Loon/Lsr/AppStore.lsr
GitHub.list|https://rule.kelee.one/Loon/GitHub.lsr
Netflix.list|https://rule.kelee.one/Loon/Netflix.lsr
YouTube.list|https://rule.kelee.one/Loon/YouTube.lsr
Disney.list|https://rule.kelee.one/Loon/Disney.lsr
Twitter.list|https://rule.kelee.one/Loon/Twitter.lsr
Facebook.list|https://rule.kelee.one/Loon/Facebook.lsr
Instagram.list|https://rule.kelee.one/Loon/Instagram.lsr
Spotify.list|https://rule.kelee.one/Loon/Spotify.lsr
Google.list|https://rule.kelee.one/Loon/Google.lsr
OneDrive.list|https://rule.kelee.one/Loon/OneDrive.lsr
EOF
}

direct_urls() {
  cat <<'EOF'
Steam.list|https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/refs/heads/master/Clash/Ruleset/Steam.list
LAN_SPLITTER.list|https://fastly.jsdelivr.net/gh/fmz200/wool_scripts@main/Loon/rule/LAN.list
mihomo.mrs|https://fastly.jsdelivr.net/gh/privacy-protection-tools/anti-ad.github.io@master/docs/mihomo.mrs
EOF
}

download_with_proxy() {
  local filename="$1" url="$2"
  tmpfile=$(mktemp)
  set +e
  http_code=$(curl -sL --connect-timeout 15 --max-time 30 \
    -x "$PROXY" \
    -A "clash.meta/1.18.0" \
    -w "%{http_code}" -o "$tmpfile" "$url" 2>/dev/null)
  size=$(wc -c < "$tmpfile" 2>/dev/null || echo 0)
  set -e
  if [ "$http_code" = "200" ] && [ "$size" -gt "$MIN_SIZE" ]; then
    cp "$tmpfile" "$RULE_DIR/$filename"
    echo "  OK  $filename ($size bytes)"
    rm -f "$tmpfile"
    return 0
  else
    echo " FAIL $filename (HTTP $http_code, size $size)"
    rm -f "$tmpfile"
    return 1
  fi
}

download_direct() {
  local filename="$1" url="$2"
  tmpfile=$(mktemp)
  set +e
  http_code=$(curl -sL --connect-timeout 15 --max-time 30 \
    -w "%{http_code}" -o "$tmpfile" "$url" 2>/dev/null)
  size=$(wc -c < "$tmpfile" 2>/dev/null || echo 0)
  set -e
  if [ "$http_code" = "200" ] && [ "$size" -gt "$MIN_SIZE" ]; then
    cp "$tmpfile" "$RULE_DIR/$filename"
    echo "  OK  $filename ($size bytes)"
    rm -f "$tmpfile"
    return 0
  else
    echo " FAIL $filename (HTTP $http_code, size $size)"
    rm -f "$tmpfile"
    return 1
  fi
}

ok=0
fail=0

echo "=== Proxy check ==="
proxy_test=$(curl -s --connect-timeout 5 -x "$PROXY" -o /dev/null -w "%{http_code}" "http://www.gstatic.com/generate_204" 2>/dev/null)
if [ "$proxy_test" != "204" ]; then
  echo "WARNING: Proxy $PROXY not responding, kelee.one download will likely fail"
fi

mkdir -p "$RULE_DIR"

echo ""
echo "=== Downloading from kelee.one (via proxy) ==="
while IFS='|' read -r filename url; do
  if download_with_proxy "$filename" "$url"; then
    ok=$((ok+1))
  else
    fail=$((fail+1))
  fi
done < <(source_urls)

echo ""
echo "=== Downloading from GitHub/CDN (direct) ==="
while IFS='|' read -r filename url; do
  if download_direct "$filename" "$url"; then
    ok=$((ok+1))
  else
    fail=$((fail+1))
  fi
done < <(direct_urls)

echo ""
echo "=== Result: $ok OK, $fail failed ==="

cd "$REPO_DIR"
if git diff --quiet && git diff --cached --quiet; then
  echo "No changes, skip push."
  exit 0
fi

git add -A
git commit -m "Auto update rule files $(date '+%Y-%m-%d %H:%M')"
git push
echo "Pushed to GitHub."
