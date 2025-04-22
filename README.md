### `README.md`

```markdown
# Sheet‑Shell Demo 🗂️

Run shell‑style commands from a Google Sheet. A single Cloud Function (`shellRunner`)
does the work.

| Sheet Cell Value | Action |
|------------------|--------|
| `make_zip`       | Build a portable‑Python ZIP in `/tmp` |
| `email alice@…`  | Send that ZIP via Gmail (App Password) |
| `push_github`    | Commit & push every file to this repo |
| *anything else*  | Echo JSON back (sanity check) |

---

## Requirements

| Item | Why |
|------|-----|
| **Google Cloud project** with Cloud Functions Gen 2 enabled | Host the Python function |
| **Gmail App Password** (16 chars) | SMTP send |
| **Classic GitHub PAT** (`ghp_…`) with **`repo`** scope | Create & push the repo |

---

## Files

```
.
├── main.py                 # Cloud Function entry‑point
├── requirements.txt        # PyPI deps (PyGithub)
├── utils/emailer.py        # SMTP helper
└── master.sh               # one‑shot deploy + Git push
```

---

## Quick start

1. Open **`master.sh`** and fill the four variables at the top.
2. Run:

```bash
chmod +x master.sh
./master.sh
```

The script will:

* deploy / refresh **shellRunner**
* create (or confirm) the GitHub repo
* commit **all** files and push to `main`
* print the Cloud Function URL and repo URL

---

## Optional — Sheet menu

```javascript
const ENDPOINT = 'https://REGION-PROJECT.cloudfunctions.net/shellRunner';

function onOpen() {
  SpreadsheetApp.getUi().createMenu('Shell')
    .addItem('Run A2', 'runShell')
    .addToUi();
}

function runShell() {
  const sh  = SpreadsheetApp.getActiveSheet();
  const cmd = String(sh.getRange('A2').getValue()).trim();
  if (!cmd) return;
  const res = UrlFetchApp.fetch(ENDPOINT, {
    method: 'post',
    contentType: 'application/json',
    payload: JSON.stringify({cmd})
  });
  sh.getRange('B2').setValue(res.getContentText());
}
```

---

## Clean‑up

```bash
gcloud functions delete shellRunner --region us-central1
```

MIT License – no warranty
```

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
```
