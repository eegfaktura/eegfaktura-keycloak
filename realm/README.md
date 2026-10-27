# Realm-Config-as-Code (`EEGFaktura`)

Deklarative, versionierte Quelle der Wahrheit für den `EEGFaktura`-Keycloak-Realm,
angewandt via [keycloak-config-cli](https://github.com/adorsys/keycloak-config-cli).
Entscheidung: **ADR-0009** (platform-Repo). Treiber: **ADR-0008** (Keycloak-pro-Env).

> Stand 2026-10-17: Apply gegen einen leeren Keycloak 26.7.4 lokal geprüft (config-cli
> 6.4.0-26.0.5): Realm, Clients, User Profile, Bruteforce und Events werden angelegt, ein zweiter
> Apply ändert nichts. **Offen:** `scripts/verify-realm.sh` (platform-Repo) 6/6 und der Diff gegen
> den Dev-Realm — erst danach gegen einen bestehenden Realm anwenden.

## User Profile, Bruteforce, Events
- **User Profile:** `tenant` ist nicht deklariert; `unmanagedAttributePolicy: ADMIN_EDIT` → nur
  Admins (admin-backend über die Admin-API) sehen und setzen es. Ohne die Einstellung verwirft ein
  neuer Realm `tenant` auch beim Setzen durch den Admin. config-cli übernimmt das User Profile nur
  als Komponente `declarative-user-profile` (ein Top-Level-Key `userProfile` wird ignoriert).
- **Bruteforce:** temporäre Sperre nach 10 Fehlversuchen, wachsend bis 15 min, keine Dauersperre.
- **Bruteforce, Trade-off:** wer einen Benutzernamen kennt, kann das Konto mit Fehlversuchen
  vorübergehend sperren; zwei Fehlversuche innerhalb 1 s sperren für 60 s (Keycloak-Default).
- **Events:** nur Anmeldung/Abmeldung, Passwort-, Profil- und Credential-Änderungen, Sperren
  (`enabledEventTypes`); Admin-Ereignisse ohne Inhalt. Je 90 Tage (`eventsExpiration`,
  `attributes.adminEventsExpiration`). Events enthalten Benutzer-ID und IP-Adresse.
- **User-Profile-Kopie:** jeder Apply überschreibt das Profil des Realms (Default von KC 26.7.4 +
  Policy); im UI ergänzte Attribute gehen verloren.
- **Laufende Instanzen** (Prod inkl. Pilot, dev, env-billing) wurden bisher nicht mit dieser Datei
  aufgesetzt. Dort sind User Profile, Bruteforce und Events seit 2026-10-17 per kcadm gesetzt
  (gleiche Werte).

## Mandanten und Gruppen
- **`tenant`-Kodierung:** ein JSON-String **pro Wert** (`"RC100100"`, `"GC106668"`), nie ein
  JSON-Array-Text in einem Wert. Der App-Client (`tenantAttributeMapper`) und der API-Client
  (`tenantIds`) mappen ihn gleich: multivalued, aggregiert, JSON → flaches Array
  `["RC100100","GC106668"]`, das jeder Service als `[]string` liest (keycloak #3, 261005-ca1).
- **`access_groups`:** beide Clients tragen den Group-Mapper (voller Pfad).
- **Pro-EEG-Gruppen** `/eeg/<RC>/<ROLLE>` (`EEG_ADMIN`, `EEG_MANAGER`, `MEMBER`) werden von
  Operator-Werkzeugen über die Admin-API angelegt, **nicht** von dieser Datei (`/eeg` ist nicht
  deklariert). config-cli wendet diese Datei bei jedem Apply an; ob es unter `no-delete` nicht
  deklarierte Untergruppen beschneidet, ist nicht geprüft. Die globalen Gruppen `EEG_ADMIN/OWNER/USER` bleiben, solange Legacy-Services sie lesen.
- **Realm-Rolle `api_management`:** Betrieb des API-Gateways (Management-API, Dashboard), keine EEG-Daten.
- **Passwort-Richtlinie:** `length(12) and notUsername(undefined)` (Runbook-Wert).
- **Vor jedem Apply auf Pilot/Prod:** gegen den Live-Realm vergleichen. config-cli überschreibt die
  Realm-Felder dieser Datei — `passwordPolicy`, aber auch `failureFactor` und `eventsExpiration`,
  wo die Datei von Prod abweicht. Ein entfernter Schlüssel setzt nichts zurück: ein Rollback setzt
  `passwordPolicy` ausdrücklich auf den alten Wert.
- **`length(12)` und die Admin-Registrierung:** admin-backend legt den Benutzer an und setzt das
  Passwort danach; lehnt Keycloak ein kürzeres Passwort ab, bleibt ein Konto ohne Passwort und
  ohne Gruppen zurück. Die Richtlinie erst anwenden, wenn das Admin-Formular mindestens 12 Zeichen
  verlangt; bestehende Benutzer betrifft sie nicht (geprüft wird nur beim Setzen).

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
- **`managed: no-delete`** (im Job, inkl. `IMPORT_MANAGED_COMPONENT`) → config-cli löscht **keine**
  nicht-deklarierten Objekte (z. B. Key-Provider).
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
