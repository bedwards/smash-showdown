#!/bin/bash
# Batch create GitHub issues with rate limiting
# Usage: ./create-issues.sh issues.json

set -e

DELAY_SECONDS=2  # Delay between API calls
MIN_REMAINING=100  # Stop if rate limit below this

check_rate_limit() {
    remaining=$(gh api rate_limit --jq '.resources.graphql.remaining')
    echo "[Rate Limit] $remaining requests remaining"
    if [ "$remaining" -lt "$MIN_REMAINING" ]; then
        echo "[ERROR] Rate limit too low ($remaining < $MIN_REMAINING). Stopping."
        exit 1
    fi
}

create_issue() {
    local title="$1"
    local body="$2"
    local labels="$3"

    check_rate_limit

    echo "[Creating] $title"
    url=$(gh issue create --title "$title" --body "$body" --label "$labels" 2>&1)
    echo "[Created] $url"

    sleep "$DELAY_SECONDS"
}

# Example usage with inline issues
# create_issue "My Issue Title" "Issue body here" "enhancement,priority:high"

echo "Issue creation tool ready."
echo "Usage: source this script and call create_issue"
echo "Or pipe JSON: cat issues.json | jq -r '.[] | @base64' | while read issue; do ..."
