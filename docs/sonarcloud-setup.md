# SonarCloud Setup — ExpenseMy

SonarCloud provides static analysis (code smells, bugs, security hotspots) and
tracks code coverage for ExpenseMy. This guide walks through linking the repo,
configuring CI, and reading the dashboard.

Related files:
- [`sonar-project.properties`](../sonar-project.properties) — scanner config
- [`.github/workflows/sonar.yml`](../.github/workflows/sonar.yml) — CI workflow

---

## 1. Create a SonarCloud account

1. Go to [sonarcloud.io](https://sonarcloud.io) and click **Log in**.
2. Choose **With GitHub** and authorize SonarCloud.
3. SonarCloud is **free for public repositories**. Private repos require a paid
   plan.

---

## 2. Import the GitHub repository

1. In SonarCloud click **+** (top right) → **Analyze new project**.
2. If prompted, install the **SonarCloud GitHub App** and grant it access to the
   `Mannagurung121/ExpenseMy` repository (or your fork).
3. Select an **organization**. SonarCloud creates one named after your GitHub
   account/org (e.g. `mannagurung121`) — note this value.
4. Select the **ExpenseMy** repository and click **Set Up**.
5. Choose **GitHub Actions** as the analysis method (we use the workflow, not
   SonarCloud's automatic analysis — turn automatic analysis **off** so the two
   don't conflict).

---

## 3. Get the project key and organization key

After import, SonarCloud shows:

- **Project Key** — typically `Mannagurung121_ExpenseMy`
- **Organization Key** — typically `mannagurung121` (lowercase)

Confirm these match `sonar-project.properties`:

```properties
sonar.projectKey=Mannagurung121_ExpenseMy
sonar.organization=mannagurung121
```

If they differ, update `sonar-project.properties` to the exact values shown in
SonarCloud (the keys are case-sensitive).

---

## 4. Add SONAR_TOKEN to GitHub Secrets

1. In SonarCloud: **My Account → Security → Generate Tokens**.
2. Enter a name (e.g. `ExpenseMy CI`), choose **Type: Project Analysis Token**
   (or a global user token), and click **Generate**. Copy it — shown once.
3. In GitHub: repo **Settings → Secrets and variables → Actions → New
   repository secret**.
4. Name it exactly `SONAR_TOKEN` and paste the value.

> `GITHUB_TOKEN` is provided automatically by GitHub Actions and needs no setup;
> the workflow uses it so SonarCloud can decorate pull requests with findings.

---

## 5. How the CI workflow runs

`.github/workflows/sonar.yml` runs on push and PRs to `main`:

1. Checks out with full history (`fetch-depth: 0`) for accurate blame/new-code.
2. Builds and tests with `-enableCodeCoverage YES`, writing `SonarResults.xcresult`.
3. Converts the xcresult coverage into the **SonarQube generic coverage XML**
   (`sonarqube-generic-coverage.xml`) — the path declared in
   `sonar.swift.coverage.reportPaths`.
4. Installs `sonar-scanner` via Homebrew and runs it with `SONAR_TOKEN`.

The first successful run populates the dashboard.

---

## 6. Reading the SonarCloud dashboard

Open your project at `https://sonarcloud.io/project/overview?id=Mannagurung121_ExpenseMy`.

Key panels:

| Metric | What it means |
|---|---|
| **Quality Gate** | Pass/Fail summary against your gate conditions (see §7). |
| **Bugs** | Code likely to behave incorrectly at runtime. |
| **Vulnerabilities** | Security-sensitive issues with known exploit patterns. |
| **Security Hotspots** | Security-sensitive code requiring manual review (review and mark Safe/Fixed). |
| **Code Smells** | Maintainability issues; aggregated into technical-debt time. |
| **Coverage** | % of executable lines covered by tests (from the converted xcresult). |
| **Duplications** | % of duplicated lines. |

The **New Code** tab is the one to watch on PRs — SonarCloud's "Clean as You
Code" model gates on issues introduced by the change, not legacy debt.

---

## 7. Quality Gate configuration

The default gate ("Sonar way") applies to **new code** and fails a PR if any of:

- New bugs, vulnerabilities, or unreviewed security hotspots > 0
- New code coverage below the threshold (default 80%)
- New duplicated lines above the threshold (default 3%)
- Maintainability/reliability/security rating on new code worse than A

To adjust: **Project → Administration → Quality Gate**, or define an
organization-wide gate under the org's **Quality Gates** tab. For an early-stage
app you may lower the new-code coverage threshold until the suite grows; raise it
back toward 80% as coverage improves.

To enforce the gate on PRs, ensure **Branch protection** on `main` requires the
SonarCloud status check to pass before merge (GitHub → Settings → Branches).

---

## 8. Troubleshooting

- **"Project not found" / 401** — `SONAR_TOKEN` missing or wrong, or
  `sonar.projectKey`/`sonar.organization` don't match SonarCloud. Re-check §3–4.
- **Coverage shows 0%** — the conversion step produced an empty file. Confirm
  tests ran with `-enableCodeCoverage YES` and the `.xcresult` exists; check the
  "Convert xcresult coverage" step log.
- **Duplicate analysis warnings** — turn off SonarCloud **Automatic Analysis**
  (Administration → Analysis Method) since this repo uses CI-based analysis.
