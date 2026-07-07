# Realm-Config-as-Code (`EEGFaktura`)

Deklarative, versionierte Quelle der Wahrheit für den `EEGFaktura`-Keycloak-Realm,
angewandt via [keycloak-config-cli](https://github.com/adorsys/keycloak-config-cli).
Entscheidung: **ADR-0009** (platform-Repo). Treiber: **ADR-0008** (Keycloak-pro-Env).

> ⚠️ **ERST-CUT — noch nicht gegen einen echten Apply verifiziert.** Vor Merge/Nutzung:
> gegen einen **leeren** KC anwenden und `scripts/verify-realm.sh` (platform-Repo) **6/6**
> grün bekommen. Gegen den aktuellen Dev-Realm diffen (idempotenter Re-Apply ohne Drift).

## Was es ersetzt
| Bisher (drei driftende Artefakte) | Neu |
|---|---|
| Compose-`realm-export.json` (`--import-realm`, nur import-if-absent) | `realm/EEGFaktura.yaml` (create **+** update) |
| imperativer `bootstrap-realm.sh` (kcadm) | dieselbe YAML, deklarativ |
| `keycloak-realm-spec.md` (Prosa) | bleibt Referenz; die YAML **ist** die Quelle |

## Dateien
- `EEGFaktura.yaml` — die Realm-Definition (Realm-Settings, Clients app/api/admin, tenant-/
  Group-/Audience-Mapper, Gruppen `EEG_ADMIN/OWNER/USER`, Realm-Roles). String-Felder mit
  externer Identität sind als `$(env:VAR)` templatisiert.
- `apply-job.yaml` — Referenz-Kubernetes-Job (config-cli) + Beispiel-Hosts-ConfigMap.

## Anwenden (Dev)
```sh
# 1) Realm-YAML als ConfigMap
kubectl -n eegfaktura create configmap eegfaktura-realm-config \
  --from-file=EEGFaktura.yaml=realm/EEGFaktura.yaml \
  --dry-run=client -o yaml | kubectl apply -f -
# 2) Hosts-ConfigMap (pro Env die Env-Hosts) — Beispiel steckt in apply-job.yaml
# 3) Job
kubectl -n eegfaktura apply -f realm/apply-job.yaml
kubectl -n eegfaktura logs -f job/eegfaktura-realm-config-apply
```

## Env-Substitution (`$(env:VAR)`)
| Variable | Zweck | Dev-Base |
|---|---|---|
| `AUTH_URL` | `realm.attributes.frontendUrl` (Issuer-Match!) | `https://auth.eegfaktura-dev.duckdns.org` |
| `CUSTOMER_HOST` | app-Client redirect/webOrigin | `eegfaktura-dev.duckdns.org` |
| `ADMIN_HOST` | admin-Client redirect/webOrigin | `admin.eegfaktura-dev.duckdns.org` |

Pro `env/<name>` (ADR-0008): flache Wildcard-Hosts `<name>-…​.eegfaktura-dev.duckdns.org`.
**Nur String-Felder** werden substituiert; zonen-variante Booleans/Ints (`verifyEmail`,
`accessTokenLifespan`) stehen auf Dev-Werten und werden für Pilot/Prod per Overlay überschrieben.

## Sicherheits-/Design-Leitplanken
- **`managed: no-delete`** (im Job) → config-cli löscht **keine** nicht-deklarierten Objekte.
- **Signing-Keys sind NICHT im Scope** — bleiben pro KC-Instanz (First-Boot). Consumer-
  Verdrahtung (dynamische JWKS bzw. filestore-Pubkey-Extraktion) ist ein separater Schritt.
- **`aud=string "account"`** muss erhalten bleiben: app-Client **ohne** Audience-Mapper,
  `roles`-Scope **mit** audience-resolve, Customer-User **ohne** Client-Roles auf api/admin.
- **config-cli-Image an die KC-Major pinnen** (KC 26 → passende Line; kein `:latest`).

## Bewusst offen (vor Prod/Vollständigkeit klären)
- **`admin-cli`** (KC-Built-in): Spec will confidential + serviceAccounts + Secret; `bootstrap-realm.sh`
  fasst es **nicht** an → gegen Live-Realm verifizieren, dann mit `$(env:ADMIN_CLI_SECRET)` ergänzen.
- **api-Client-Secret**: Dev generiert KC; Pilot/Prod `$(env:API_CLIENT_SECRET)` aus Secret-Store.
- **Test-User** (`faktura_admin`, `te100200_admin`) + `tenant`-Attribut: aktuell Seed
  (`bootstrap-poc-data.sh`). Offene Frage (ADR-0009/Konzept §11.5): in-Config vs Seed. config-cli
  **kann** User-Attribute setzen (löst das kcadm-KC25+-Attribut-Problem) — Entscheidung offen.
- **Client-Scopes**: bewusst nicht deklariert → KC-Defaults bleiben (`no-delete`); der kritische
  `roles`-Scope-audience-resolve ist Default.
