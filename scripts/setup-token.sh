#!/usr/bin/env bash
# One-time token setup for Practice Court. Run in YOUR terminal:
#   bash <(curl -s https://raw.githubusercontent.com/jerryshi042003/practice-court/main/scripts/setup-token.sh)
# Pastes stay local; secrets go only to GitHub Actions' encrypted store.
set -euo pipefail
APP_ID="2120836272184176"
REPO="jerryshi042003/practice-court"
V="v21.0"

echo "1) Paste the SHORT-LIVED token from Graph API Explorer (input hidden):"
read -rs SHORT; echo
echo "2) Paste the APP SECRET (developers.facebook.com -> Practice Court -> App settings -> Basic -> App secret -> Show):"
read -rs SECRET; echo

echo "-> exchanging for a 60-day token..."
LL=$(curl -s "https://graph.facebook.com/${V}/oauth/access_token?grant_type=fb_exchange_token&client_id=${APP_ID}&client_secret=${SECRET}&fb_exchange_token=${SHORT}" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("access_token",""))')
[ -n "$LL" ] || { echo "!! exchange failed (check the two pastes)"; exit 1; }

echo "-> finding your Page and linked Instagram account..."
PAGE_ID=$(curl -s "https://graph.facebook.com/${V}/me/accounts?access_token=${LL}" | python3 -c 'import sys,json;d=json.load(sys.stdin).get("data",[]);print(d[0]["id"] if d else "")')
[ -n "$PAGE_ID" ] || { echo "!! no Page found on this token"; exit 1; }
IG_ID=$(curl -s "https://graph.facebook.com/${V}/${PAGE_ID}?fields=instagram_business_account&access_token=${LL}" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("instagram_business_account",{}).get("id",""))')
[ -n "$IG_ID" ] || { echo "!! Page has no linked Instagram professional account — redo the popup and select @jerrythegoatshi"; exit 1; }

echo "-> smoke test: business_discovery on rodri_ovide..."
COUNT=$(curl -s "https://graph.facebook.com/${V}/${IG_ID}?fields=business_discovery.username(rodri_ovide)%7Bmedia.limit(2)%7Bpermalink%7D%7D&access_token=${LL}" | python3 -c 'import sys,json;print(len(json.load(sys.stdin).get("business_discovery",{}).get("media",{}).get("data",[])))')
echo "   got ${COUNT} posts (want >0)"

echo "-> storing GitHub Actions secrets..."
printf '%s' "$LL"    | gh secret set IG_ACCESS_TOKEN -R "$REPO" --body -@- 2>/dev/null || gh secret set IG_ACCESS_TOKEN -R "$REPO" --body "$LL"
gh secret set IG_USER_ID -R "$REPO" --body "$IG_ID"

echo "-> triggering first refresh run..."
gh workflow run refresh.yml -R "$REPO" || true

echo "DONE. IG user id: ${IG_ID}. Token expires in ~60 days (rerun this script to renew)."
