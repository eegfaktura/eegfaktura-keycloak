# Changelog

All notable changes to **eegfaktura-keycloak (Keycloak image for eegfaktura)** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and
versioning follows the deployment release tags. Detailed diffs stay in the `git log`;
this changelog highlights the changes relevant for overview and operations.

## [Unreleased]

### CI
- `pr-checks.yml`: unit tests and the full test suite on every pull request (unit = the realm files parse; full = the image builds, starts against PostgreSQL and keycloak-config-cli applies the realm).
- `security-scan.yml`: leaked secrets in the new commits (Gitleaks, Trivy), vulnerable dependencies (Trivy, OSV-Scanner) and misconfigurations (Trivy). A pull request fails on what it adds; pushes to the default branch and a weekly run fail on every CRITICAL finding (HIGH is reported; `SCAN_FAIL_ON`). Scanners are fixed versions checked by SHA-256, each release at least 7 days old; actions pinned by commit SHA.
- `security-scan.yml`: for now the vulnerable-dependency and misconfiguration findings are only reported (`SCAN_FAIL_ON: none` — the gate prints a warning in every run that it is off); leaked secrets still fail. To be tightened again once the known findings are paid down.
- `security-scan.yml`: the dependency scan no longer asks Maven Central for each pom — a new job "Build dependencies" resolves the poms beforehand (pinned Maven 3.9.11, cached) and hands them to Trivy; on GitHub's shared runner IPs Trivy's own lookups ended in `429 Too Many Requests` and failed the scan. The secret scan runs with `--offline-scan`; the gates no longer run (with a misleading "unreadable report") after a failed scan.
- `rolling-release.yml`: no image build on a draft pull request — it runs when the pull request is marked ready for review (`ready_for_review`) and on every later push to it; `pr-checks.yml` still checks drafts. Pushes, tags and the deploy dispatch are unchanged.

### Added
- CI builds `env/**` branches and deploys the resulting image into the matching feature
  environment (ADR-0008): a push to `env/<name>` pins this service in namespace `env-<name>`
  to that branch's `sha-…` image. Previously only the default branch, tags and `preview/**`
  produced an image at all. The environment itself is still provisioned manually.

## [1.0.2] – 2026-09-07

### Security
- **Keycloak 26.4.7 → 26.7.3**, schließt **CVE-2026-18963** / GHSA-4gv3-mc9p-5wqc
  (CVSS 9.1): ein unauthentifizierter Angreifer konnte den Passwort-Reset für einen
  beliebigen Benutzer erzwingen, ohne den E-Mail-Bestätigungslink zu benötigen, und direkt
  neue Credentials setzen — vollständige Kontoübernahme, auch von EEG_ADMIN-Konten.
  Unser Keycloak ist öffentlich erreichbar, der Befund war damit real und nicht theoretisch.

  **Warum drei Minor-Versionen:** Das Advisory nennt 26.4.15 als Fix — diese Version gibt es
  nur im Red-Hat-Build. Upstream (`quay.io/keycloak/keycloak`) endet die 26.4-Linie bei
  genau unserer 26.4.7 und die 26.6-Linie bei 26.6.4, während das Advisory dort 26.6.6
  verlangt. **26.7.2 ist die niedrigste upstream verfügbare gefixte Version**, 26.7.3 die
  aktuelle.

  **Zwischenlösung, die vorausging:** `resetPasswordAllowed=false` im Prod-Realm
  (02.09.2026), extern verifiziert über `GET /login-actions/reset-credentials` →
  HTTP 400 „Reset Credential not allowed". Nach dem Upgrade sollte die Funktion wieder
  eingeschaltet werden — sie ist nur als Notnagel aus.

### Added
- **Realm-Config-as-Code (ADR-0009):** deklarative Realm-Definition `realm/EEGFaktura.yaml`
  (keycloak-config-cli) als versionierte Quelle der Wahrheit + Referenz-Apply-Job
  `realm/apply-job.yaml` + `realm/README.md`. Ersetzt (als operative Quelle) den
  Compose-`realm-export.json`-Import und den imperativen `bootstrap-realm.sh`; KC startet leer,
  config-cli legt den Realm create+update an, `managed: no-delete`, Env-Hosts via `$(env:VAR)`.
  **Erst-Cut** — vor Merge/Nutzung gegen einen echten Apply verifizieren (`verify-realm.sh` 6/6).
  Bewusst offen: `admin-cli`-Built-in, Client-Secrets, Test-User in-Config-vs-Seed (siehe README).

### Changed
- CI: Preview-Deployments (ADR-0007) — Push auf `preview/**` baut+deployt on-demand in die Dev-Zone (sha-pinned, kein `:latest`), Auto-Reset bei Branch-Delete.

## [1.0.1] – 2026-06-29

### Fixed
- Restore the custom `eegfaktura-ui` login theme that was baked into the previous prod image but missing from the source-built image, so the login screen shows the eegfaktura branding again instead of the default Keycloak theme. The realm already references `loginTheme=eegfaktura-ui`.

## [1.0.0] – 2026-06-28

Part of the unified source-build cutover of the eegfaktura suite.

### Changed
- Docker: split ENTRYPOINT/CMD, pinned Keycloak `26.4.7`. (#2)
- CI: dispatch-deploy bridge for platform auto-rollout; push to the registry's
  development tier (ADR-0005). (#3, #4)

## Earlier releases

Shipped as image tags `v0.2.0` and `v0.3.0` before the 1.0.0 cutover.
