# Changelog

All notable changes to **eegfaktura-keycloak (Keycloak image for eegfaktura)** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and
versioning follows the deployment release tags. Detailed diffs stay in the `git log`;
this changelog highlights the changes relevant for overview and operations.

## [Unreleased]

## [1.0.0] – 2026-06-28

Part of the unified source-build cutover of the eegfaktura suite.

### Changed
- Docker: split ENTRYPOINT/CMD, pinned Keycloak `26.4.7`. (#2)
- CI: dispatch-deploy bridge for platform auto-rollout; push to the registry's
  development tier (ADR-0005). (#3, #4)

## Earlier releases

Shipped as image tags `v0.2.0` and `v0.3.0` before the 1.0.0 cutover.
