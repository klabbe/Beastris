# Admin Operations

Operations that require Firebase Admin SDK access (e.g. GDPR deletion requests that come in via e-mail).

---

## One-time setup

### 1. Download the service account key

1. Go to [Firebase Console](https://console.firebase.google.com) → project **beastris-game-90b1b**
2. **Project settings** → **Service accounts** tab
3. Click **Generate new private key** → confirm → a `.json` file downloads
4. Save it as **`scripts/serviceAccountKey.json`** (exact path)

> ⚠️ This file gives full admin access to the Firebase project.  
> It is listed in `.gitignore` and must **never** be committed to git.  
> Keep it only on your own machine.

### 2. Install dependencies (once)

```bash
cd /Users/klas/Beastris/scripts
npm install
```

---

## Delete a user account (GDPR Art. 17 request)

When you receive an account deletion request by e-mail, run:

```bash
cd /Users/klas/Beastris
node scripts/delete_user.mjs the-users-email@example.com
```

The script:
1. Looks up the UID from the e-mail address
2. Anonymises all leaderboard entries (clears the `uid` field — scores stay on the global leaderboard but are no longer linked to the account)
3. Deletes the `users/{uid}` Firestore document
4. Deletes the Firebase Authentication account

You have **30 days** from receiving the request to complete the deletion (as stated in account-deletion.html).

---

## Security — risks and mitigations

### What is the risk?

`serviceAccountKey.json` is a long-lived credential that grants **unrestricted admin access** to the Firebase project:
- Read and write all Firestore data
- Create, delete, and impersonate any user
- Access Firebase Storage, etc.

If this file leaks, an attacker has full control of the backend.

### Is the script itself a risk?

**No.** The script runs locally on your machine only. It cannot be reached from the internet. No server, no open port, no webhook.

The only risk is the **key file leaking**, not the script itself.

### How to protect the key

| Rule | Why |
|---|---|
| Never `git add` the key file | `.gitignore` already prevents this — double-check with `git status` before committing |
| Don't copy it to cloud storage, e-mail, or iCloud | Those services could be compromised |
| Keep only one copy — on your Mac, in `scripts/` | Fewer copies = smaller attack surface |
| Revoke and regenerate if you suspect exposure | Firebase Console → Service accounts → delete the old key → generate new one |

### What if I accidentally push it to GitHub?

Act immediately:
1. Firebase Console → **Project settings → Service accounts** → find the leaked key → **Delete**
2. GitHub → repo → **Settings → Secrets / history** → check if the file appeared in any commit
3. Use `git filter-repo` or contact GitHub support to purge the commit history if needed
4. Generate a new key

### Can someone abuse the deletion script against users without the key?

No. The script requires `serviceAccountKey.json` to exist locally. Without it, the script exits immediately with an error. No remote execution path exists.

---

## Revoking or rotating the key

If you want to rotate the key (good practice annually):

1. Firebase Console → **Project settings → Service accounts**
2. Generate a new key → save as `scripts/serviceAccountKey.json` (overwrites old)
3. Delete the old key entry in the Firebase Console

The old key stops working immediately after you delete it in the console.
