#!/usr/bin/env bash
set -euo pipefail

# Configuration
GITHUB_REPO="Kozea/Radicale"
ISSUE_NUMBER=2237
CURRENT_RADICAL_VER="3.8.1"  # Currently used in our add-on
NOTIFY_WEBHOOK="${NOTIFY_WEBHOOK_URL:-}"  # Optional: HA Webhook URL

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Checking Radicale Issue #${ISSUE_NUMBER} status..."

# 1. Check Issue Status
ISSUE_RESPONSE=$(curl -s --max-time 10 "https://api.github.com/repos/${GITHUB_REPO}/issues/${ISSUE_NUMBER}")
ISSUE_STATE=$(echo "$ISSUE_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('state', 'unknown'))" 2>/dev/null || echo "error")

if [ "$ISSUE_STATE" = "closed" ]; then
    echo -e "${GREEN}✅ Issue #${ISSUE_NUMBER} is CLOSED! A fix might be available.${NC}"
    NOTIFY_MSG="🎉 Radicale Issue #${ISSUE_NUMBER} is closed. Please check for a new release."
    ACTION="UPDATE_AVAILABLE"
elif [ "$ISSUE_STATE" = "open" ]; then
    echo -e "${YELLOW}⏳ Issue #${ISSUE_NUMBER} is still OPEN.${NC}"
    NOTIFY_MSG=""
    ACTION="NO_ACTION"
else
    echo -e "${RED}❌ Could not determine issue status (maybe rate limit or error).${NC}"
    NOTIFY_MSG=""
    ACTION="ERROR"
fi

# 2. Check for New Releases (Simple check: Is there a version > 3.8.1?)
# We fetch the latest release tag
LATEST_TAG=$(curl -s --max-time 10 "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tag_name', 'unknown').lstrip('v'))" 2>/dev/null || echo "unknown")

if [ "$LATEST_TAG" != "unknown" ] && [ "$LATEST_TAG" != "$CURRENT_RADICAL_VER" ]; then
    # Simple semantic version comparison (basic)
    NEWER=$(python3 -c "
import sys
def vtuple(v):
    return tuple(int(x) for x in v.split('.') if x.isdigit())
if vtuple('${LATEST_TAG}') > vtuple('${CURRENT_RADICAL_VER}'):
    print('yes')
else:
    print('no')
" 2>/dev/null || echo "unknown")
    
    if [ "$NEWER" = "yes" ]; then
        echo -e "${GREEN}🆕 New Radicale version available: v${LATEST_TAG} (Current: v${CURRENT_RADICAL_VER})${NC}"
        NOTIFY_MSG="🚀 New Radicale version v${LATEST_TAG} is available! Consider updating the add-on."
        ACTION="NEW_VERSION"
    else
        echo -e "${YELLOW}ℹ️  Latest tag v${LATEST_TAG} is not newer than v${CURRENT_RADICAL_VER}.${NC}"
    fi
fi

# 3. Send Notification if needed
if [ -n "$NOTIFY_MSG" ] && [ -n "$NOTIFY_WEBHOOK" ]; then
    echo "📤 Sending notification..."
    curl -s -X POST "$NOTIFY_WEBHOOK" \
        -H "Content-Type: application/json" \
        -d "{\"message\": \"$NOTIFY_MSG\", \"title\": \"Radicale Update Check\"}" > /dev/null
    echo -e "${GREEN}✅ Notification sent.${NC}"
elif [ -n "$NOTIFY_MSG" ]; then
    echo -e "${YELLOW}⚠️  Notification ready but no WEBHOOK URL set (env var NOTIFY_WEBHOOK_URL).${NC}"
    echo "Message: $NOTIFY_MSG"
fi

echo "🏁 Check completed."