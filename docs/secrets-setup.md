# GitHub Actions Secrets Setup — ExpenseMy

This guide explains every CI secret used by the project, where to obtain each one, and how to add them to GitHub.

---

## Secrets reference

| Secret | Used by | Description |
|---|---|---|
| `APPLE_ID` | `beta`, `release` lanes | Your Apple ID email address |
| `APP_SPECIFIC_PASSWORD` | `beta`, `release` lanes | App-specific password for automated Apple sign-in |
| `TEAM_ID` | `beta`, `release` lanes | Your 10-character Apple Developer team ID |
| `MATCH_PASSWORD` | `beta`, `release` lanes | Passphrase that encrypts the Match certificate repository |
| `MATCH_GIT_URL` | `beta`, `release` lanes | HTTPS URL of your private Match certificates repository |
| `SONAR_TOKEN` | `security-scan.yml` | Authentication token for SonarCloud static analysis |
| `DANGER_GITHUB_API_TOKEN` | `security-scan.yml` | GitHub personal access token used by Danger JS |

---

## Obtaining each secret

### `APPLE_ID`

This is the email address you use to sign in to [developer.apple.com](https://developer.apple.com) and [appstoreconnect.apple.com](https://appstoreconnect.apple.com).

**Value:** `you@example.com`

---

### `APP_SPECIFIC_PASSWORD`

Apple requires app-specific passwords for automated tools that access Apple ID services (like uploading to TestFlight).

**Steps:**
1. Go to [appleid.apple.com](https://appleid.apple.com) and sign in.
2. In the **Sign-In and Security** section, click **App-Specific Passwords**.
3. Click **Generate an app-specific password (+)**.
4. Enter a label such as `ExpenseMy CI`.
5. Click **Create**. Copy the generated password — it is shown only once.

**Format:** `xxxx-xxxx-xxxx-xxxx`

---

### `TEAM_ID`

Your Apple Developer team identifier is a 10-character alphanumeric string.

**Steps:**
1. Sign in to [developer.apple.com/account](https://developer.apple.com/account).
2. Scroll to the **Membership details** section.
3. Copy the **Team ID** value.

Alternatively, find it in Xcode under **Xcode › Settings › Accounts › (your account) › Team ID**.

**Format:** `XXXXXXXXXX` (10 characters)

---

### `MATCH_PASSWORD`

Match encrypts all certificates and profiles stored in the private Git repository using a passphrase you choose.

**Steps:**
1. Choose a strong passphrase (e.g., generate one with `openssl rand -base64 32`).
2. Run `bundle exec fastlane match init` to configure Match — it will ask for this passphrase.
3. Store the passphrase somewhere secure (password manager). You cannot recover encrypted certificates without it.

**Value:** any string you choose — keep it secret.

---

### `MATCH_GIT_URL`

The HTTPS URL of the **private** GitHub repository that Match uses to store encrypted certificates and provisioning profiles.

**Steps:**
1. Create a new **private** repository on GitHub (e.g., `your-org/certificates` or `your-username/certificates`).
2. Do not add a README or any files — Match will initialise it.
3. Copy the HTTPS clone URL.

**Format:** `https://github.com/your-org/certificates.git`

**Note:** CI reads this repository using the HTTPS URL. GitHub Actions can access private repos in the same organization automatically if you grant the workflow repository read access, or you can embed a Personal Access Token in the URL: `https://<token>@github.com/your-org/certificates.git`.

---

### `SONAR_TOKEN`

Required if the `security-scan.yml` workflow includes SonarCloud analysis.

**Steps:**
1. Sign in to [sonarcloud.io](https://sonarcloud.io) with your GitHub account.
2. Go to **My Account › Security**.
3. Under **Generate Tokens**, enter a name (e.g., `ExpenseMy`) and click **Generate**.
4. Copy the token — it is shown only once.

---

### `DANGER_GITHUB_API_TOKEN`

Required if Danger JS is used to post automated PR comments (e.g., from `security-scan.yml`).

**Steps:**
1. Go to [github.com/settings/tokens](https://github.com/settings/tokens).
2. Click **Generate new token (classic)**.
3. Give it a descriptive name: `ExpenseMy Danger`.
4. Set an expiration (90 days recommended, then rotate).
5. Select scopes: `repo` (full control of private repositories).
6. Click **Generate token** and copy the value.

**Minimum scopes:** `public_repo` for public repos; `repo` for private repos.

---

## Adding secrets to GitHub

Do this once per secret:

1. Open your repository on GitHub.
2. Go to **Settings** (top tab bar of the repo page).
3. In the left sidebar, expand **Secrets and variables** and click **Actions**.
4. Click **New repository secret**.
5. Enter the **Name** exactly as shown in the table above (e.g., `APPLE_ID`).
6. Paste the **Secret** value.
7. Click **Add secret**.

Repeat for each secret in the table.

**Verify:** After adding, the secrets appear as masked entries (you cannot view their values again). The names must match exactly — GitHub secrets are case-sensitive.

---

## Setting up the Match certificates repository

After adding `MATCH_GIT_URL` and `MATCH_PASSWORD` to GitHub Secrets, run Match locally one time to create the initial certificates:

```bash
# Install dependencies
bundle install

# Create development certificate and provisioning profile
bundle exec fastlane match development

# Create distribution (App Store) certificate and provisioning profile
bundle exec fastlane match appstore
```

Match will prompt for your Apple ID credentials and the `MATCH_PASSWORD` passphrase, then push encrypted certificates to the `MATCH_GIT_URL` repository. After this step, CI can pull and decrypt them without any manual intervention.

---

## Rotating secrets

- **`APP_SPECIFIC_PASSWORD`** — revoke and regenerate at [appleid.apple.com](https://appleid.apple.com) if compromised or every 12 months.
- **`DANGER_GITHUB_API_TOKEN`** — set an expiration when creating and replace it before it expires.
- **`MATCH_PASSWORD`** — if changed, you must re-run `bundle exec fastlane match nuke` and re-generate all certificates, then update the secret.
- **`SONAR_TOKEN`** — revocable from the SonarCloud dashboard at any time.
