#!/bin/bash

# === CHECK INPUT ===
if [ -z "$1" ]; then
  echo "Usage: $0 <organization-name>"
  exit 1
fi

ORG="$1"

# === CHECK TOKEN ===
if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: Please export your GitHub token as GITHUB_TOKEN."
  echo "Example: export GITHUB_TOKEN=your_token_here"
  exit 1
fi

PER_PAGE=100
PAGE=1

# === FETCH REPOS ===
while : ; do
  RESPONSE=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/orgs/$ORG/repos?per_page=$PER_PAGE&page=$PAGE")

  # Break if no repos in the response
  [ "$(echo "$RESPONSE" | jq '. | length')" -eq 0 ] && break

  # Print repo full names
  echo "$RESPONSE" | jq -r '.[].full_name'

  ((PAGE++))
done
