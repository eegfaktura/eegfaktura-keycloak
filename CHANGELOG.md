# Changelog

All notable changes to **eegfaktura-keycloak (Keycloak image for eegfaktura)** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and
versioning follows the deployment release tags. Detailed diffs stay in the `git log`;
this changelog highlights the changes relevant for overview and operations.

## [Unreleased]

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
