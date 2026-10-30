# Changelog

All notable changes to **eegfaktura-keycloak (Keycloak image for eegfaktura)** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and
versioning follows the deployment release tags. Detailed diffs stay in the `git log`;
this changelog highlights the changes relevant for overview and operations.

## [Unreleased]

### Changed
- **Realm config: the api client `at.ourproject.vfeeg.api` gets the group mapper** (`Group Mappers`,
  `oidc-group-membership-mapper`, claim `access_groups`, full path, ID/access/userinfo/introspection token).
  Production already has it (set by hand on 2026-10-27); this aligns realm-as-code, so dev and fresh installs
  keep their API users. Needed by eegfaktura-energystore#101 (`/query` for `/EEG_ADMIN` and `/EEG_OWNER` only).

### Security
- **CI: the release workflow pins its actions by commit SHA** (eegfaktura-dev tracking W-261028-mm6). `rolling-release.yml`
  builds and pushes the shipped image, but used floating tags (`@v4`, `@v3`, …); a moved tag ran in the job that holds
  the push credentials. Now every action is pinned to a commit, the same SHAs `pr-checks.yml` and `security-scan.yml` already
  use where the action is the same, otherwise the commit the floating tag pointed to on 2026-10-28.

## [1.0.4] – 2026-10-28

### Security
- Keycloak base image `quay.io/keycloak/keycloak:26.7.4` → `26.7.5` (release and image 2026-09-30): Keycloak
  security fixes of 26.7.5 and the libraries bcprov 1.86, netty-handler 4.1.138, freemarker 2.3.35 and
  jackson 2.21.7. Image scan (Trivy 0.75.0): 5 CRITICAL / 22 HIGH → 1 CRITICAL / 10 HIGH (the rest is in the
  UBI base and in guava/mssql-jdbc). Realm file and theme unchanged; breaking changes of 26.7.5 (client policy
  source groups by full path, disabled clients not in `aud`) do not touch `realm/EEGFaktura.yaml`.

## [1.0.3] – 2026-10-21

### Added
- CI: `pr-checks.yml` on every pull request: the realm files parse (unit); the image builds,
  starts against PostgreSQL and keycloak-config-cli applies the realm (full).
- CI: `security-scan.yml` on every pull request, on pushes to the default branch and weekly:
  leaked secrets in the new commits (Gitleaks, Trivy), vulnerable dependencies (Trivy,
  OSV-Scanner) and misconfigurations (Trivy). For now the dependency and misconfiguration
  findings are only reported (`SCAN_FAIL_ON: none`) and do not block; leaked secrets fail.
- CI: every run keeps its scan and test results as artifacts for 30 days (`scan-*`,
  `test-results-<job>`, `known-errors-<job>`) for a CI report collector; the secret scan keeps
  outcomes and counts only.
- CI builds `env/**` branches and deploys the resulting image into the matching feature
  environment (ADR-0008): a push to `env/<name>` pins this service in namespace `env-<name>`
  to that branch's `sha-…` image. Previously only the default branch, tags and `preview/**`
  produced an image at all. The environment itself is still provisioned manually.

### Changed
- Realm config (`realm/EEGFaktura.yaml`): user profile with `unmanagedAttributePolicy: ADMIN_EDIT`
  (only admins see and set `tenant`; without it a new realm drops `tenant` even when an admin sets
  it), brute-force protection (temporary lockout after 10 failures, up to 15 min) and events
  (login/logout, password, profile and credential changes, lockouts; admin events without
  content; 90 days each). Applies to Keycloaks set up from this config. The running instances were
  not set up from it: the same settings were set there via kcadm
  on 2026-10-17.

### Fixed
- Realm config could not be applied: config-cli substitutes `$(env:…)` in comments too and
  aborted on the placeholder in the header comment. `apply-job.yaml` referenced a config-cli image
  tag that does not exist (`6.4.0-26.0.4` → `6.4.0-26.0.5`).
- `apply-job.yaml` now also sets `IMPORT_MANAGED_COMPONENT=no-delete`, so an apply never deletes
  undeclared components such as key providers.
- Image: removed the hostname/proxy v1 variables (`KC_HOSTNAME_PATH=/auth`, `KC_HOSTNAME_STRICT_HTTPS`,
  `KC_HOSTNAME_STRICT_BACKCHANNEL`, `KC_PROXY=edge`, `PROXY_ADDRESS_FORWARDING`). Keycloak 26 ignores
  them and only logged the "Hostname v1 options … still in use" warning: no `/auth` path, no
  forwarded headers trusted. No behaviour change (Keycloak 26 already ignored them); prod, pilot, dev and `compose.production.yaml` set
  `KC_PROXY_HEADERS` themselves. CI (`pr-checks.yml`) no longer clears them, so it tests the image
  default.
- Image labels: they sat in the builder stage and never reached the image; now in the final stage,
  with `base.name` on the actual base (26.7.4) and `image.source` on this repository instead of
  eegfaktura-web. The fixed `version` labels ("0.1.0") are gone; the release workflow sets
  `org.opencontainers.image.version`. `FROM … AS` in upper case (BuildKit `FromAsCasing`).
- Image: `USER 1000` set explicitly in the final stage (Trivy DS-0002). The base image already ran
  as uid 1000, so the runtime user is unchanged.

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
