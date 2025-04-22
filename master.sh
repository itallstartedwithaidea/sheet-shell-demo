
---

### `master.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# 🔧 EDIT THESE FOUR LINES, THEN run ./master.sh
PROJECT_ID="your-gcp-project"              # GCP project ID
SMTP_USER="john@itallstartedwithaidea.com" # Gmail sender
SMTP_PASS="16CHAR_GMAIL_APP_PASSWORD"      # Gmail App‑Password
GITHUB_TOKEN="ghp_YOUR_CLASSIC_PAT"        # GitHub PAT with *repo* scope
###############################################################################
REGION="us-central1"
GITHUB_USER="itallstartedwithaidea"
REPO_NAME="sheet-shell-demo"

printf '\n🚀  Deploying function & pushing to GitHub…\n'

# 1 . Deploy / update Cloud Function
gcloud functions deploy shellRunner \
  --project "$PROJECT_ID" \
  --gen2 --runtime python312 --entry-point run --region "$REGION" \
  --source . --trigger-http --allow-unauthenticated --memory 128Mi \
  --set-env-vars "SMTP_USER=$SMTP_USER,SMTP_PASS=$SMTP_PASS,GITHUB_USER=$GITHUB_USER,GITHUB_TOKEN=$GITHUB_TOKEN,REPO_NAME=$REPO_NAME"

echo "✅  Function deployed"

# 2 . Ensure GitHub repo exists
GH_API="https://api.github.com"
if curl -fs -H "Authorization: token $GITHUB_TOKEN" \
       "$GH_API/repos/$GITHUB_USER/$REPO_NAME" >/dev/null; then
  echo "ℹ️  Repo exists"
else
  echo "🆕  Creating repo…" && \
  curl -s -H "Authorization: token $GITHUB_TOKEN" \
       -d "{\"name\":\"$REPO_NAME\",\"private\":false}" \
       "$GH_API/user/repos" >/dev/null
fi

# 3 . Commit & push everything
[ -d .git ] || git init -q
URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git"
(git remote | grep -q origin) || git remote add origin "$URL"
git remote set-url origin "$URL"

echo ".bash_history" >> .git/info/exclude  # never commit shell history

git add -A
git diff --cached --quiet || \
  git commit -m "sync $(date '+%F %T') via master.sh"

git branch -M main
git push -u origin main

echo -e "\n🎉  Done!"
echo "🔗 Function ⇒ https://$REGION-$PROJECT_ID.cloudfunctions.net/shellRunner"
echo "🔗 Repo     ⇒ https://github.com/$GITHUB_USER/$REPO_NAME"
