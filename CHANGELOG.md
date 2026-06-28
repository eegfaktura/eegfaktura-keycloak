# Changelog

Alle nennenswerten Änderungen an **eegfaktura-keycloak (Keycloak-Image für eegfaktura)** werden hier dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
die Versionierung an den Deployment-Release-Tags. Detail-Diffs bleiben im `git log`;
dieser Changelog hebt die für Überblick und Betrieb relevanten Änderungen hervor.

## [Unreleased]

## [1.0.0] – 2026-06-28

Teil des einheitlichen Source-Build-Cutovers der eegfaktura-Suite.

### Changed
- Docker: ENTRYPOINT/CMD getrennt, Keycloak `26.4.7` gepinnt. (#2)
- CI: dispatch-deploy-Bridge für Plattform-Auto-Rollout; Push in den
  Development-Tier der Registry (ADR-0005). (#3, #4)

## Frühere Releases

Vor dem 1.0.0-Cutover als Image-Tags `v0.2.0` und `v0.3.0` ausgeliefert.
