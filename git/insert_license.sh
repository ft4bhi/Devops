#!/bin/bash

# === INPUT ===
if [ -z "$1" ]; then
  echo "Usage: $0 <organization-name>"
  exit 1
fi

ORG="$1"

# === TOKEN CHECK ===
if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ Error: Please export your GitHub token as GITHUB_TOKEN"
  exit 1
fi

# === LICENSE TEXT ===
LICENSE_CONTENT=$(cat <<EOF
Copyright (c) 2025 Shadil Am. All rights reserved.

1. DEFINITIONS  
   “Repository” means this source code and its associated files.  
   “You” means any individual or entity that forks, clones, copies, views, or otherwise accesses the Repository.

2. LICENSE AND RESTRICTIONS  
   This Repository is proprietary and confidential. You may *not* use, copy, modify, distribute, display, execute, publish, sublicense, or sell it in whole or in part without express prior written permission from Shadil Am.  
   *Exception:* You may fork the Repository and submit pull requests on GitHub solely for the purpose of contributing code back. Such usage is strictly limited to GitHub’s pull-request system and does not grant any other rights.

3. NO IMPLIED LICENSE  
   No license—express, implied, by estoppel, or otherwise—to any intellectual property is granted except as expressly stated above.

4. TERMINATION  
   Any use beyond the limited exception in Section 2 will immediately terminate any rights you may have under this Agreement.

5. DISCLAIMER OF WARRANTIES  
   This Repository is provided “AS IS,” without any warranty, express or implied. To the maximum extent permitted by applicable law, Shadil Am disclaims all warranties.

6. LIMITATION OF LIABILITY  
   Shadil Am will not be liable for any special, indirect, incidental, or consequential damages arising out of or in connection with this Repository.

7. GOVERNING LAW & JURISDICTION  
   This Agreement is governed by and construed under the laws of the State of Kerala, Republic of India, without regard to its conflict-of-law rules. You irrevocably submit to the exclusive jurisdiction of the courts located in Kochi, Kerala, India, for any dispute arising under or relating to this Agreement.

8. CONTACT  
   Permission requests or inquiries should be sent to *shadilrayyan2@gmail.com*.
EOF
)

LICENSE_ENCODED=$(echo "$LICENSE_CONTENT" | base64 | tr -d '\n')
PER_PAGE=100
PAGE=1

while : ; do
  # === Get Repositories ===
  REPOS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/orgs/$ORG/repos?per_page=$PER_PAGE&page=$PAGE")

  # === Check if it's a valid response ===
  if echo "$REPOS" | jq -e 'has("message")' >/dev/null; then
    echo "❌ GitHub API Error: $(echo "$REPOS" | jq -r '.message')"
    exit 1
  fi

  COUNT=$(echo "$REPOS" | jq '. | length')
  [ "$COUNT" -eq 0 ] && break

  for repo in $(echo "$REPOS" | jq -r '.[].name'); do
    echo "🔍 Processing $ORG/$repo..."

    # === Check if LICENSE exists ===
    FILE_INFO=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/$ORG/$repo/contents/LICENSE")

    # If error occurred (e.g., 404), ignore sha
    if echo "$FILE_INFO" | jq -e 'has("message")' >/dev/null; then
      SHA=""
    else
      SHA=$(echo "$FILE_INFO" | jq -r '.sha // empty')
    fi

    # === Create or Update LICENSE ===
    echo "📄 Creating/Updating LICENSE..."
    RESULT=$(curl -s -X PUT -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      https://api.github.com/repos/$ORG/$repo/contents/LICENSE \
      -d @- <<EOF
{
  "message": "chore: add or replace LICENSE with proprietary license",
  "content": "$LICENSE_ENCODED",
  "sha": "$SHA"
}
EOF
)

    if echo "$RESULT" | jq -e 'has("content")' >/dev/null; then
      echo "✅ LICENSE updated in $repo"
    else
      echo "❌ Failed to update $repo: $(echo "$RESULT" | jq -r '.message')"
    fi
  done

  ((PAGE++))
done

echo "🎉 All done!"
