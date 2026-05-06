# Demo App

A minimal full-stack demo wiring together:

| Layer | Technology |
|---|---|
| API | Java 21 · Spring Boot 3 · Spring Security (OAuth2 resource server) |
| Frontend | React 18 · Vite · oidc-client-ts (Auth Code + PKCE) |
| Auth / Token service | Curity Identity Server |
| Database | PostgreSQL 16 |
| Runtime | Docker Compose |

## Architecture

```
Browser
  │  Login redirect (Authorization Code + PKCE)
  ▼
Curity :8443  ──── issues JWT access token
  │
  │  Bearer token
  ▼
Spring Boot API :8080  ──── validates JWT via JWKS endpoint
  │
  │  JPA
  ▼
PostgreSQL :5432
```

## Prerequisites

- Docker (with Compose v2)
- `openssl` and `python3` (for `setup.sh`)
- A **free** Curity developer license — get one at <https://developer.curity.io>

## First-time setup

```bash
# 1. Place your Curity license
cp ~/Downloads/license.json curity/license.json

# 2. Generate keys, TLS cert, and Curity config
./setup.sh

# 3. Start everything
docker compose up --build
```

### Self-signed certificate warning

Because `setup.sh` generates a self-signed TLS cert for Curity, your browser
will show a warning when the frontend redirects to
`https://localhost:8443` for the first time.

**Navigate directly to `https://localhost:8443` and accept the cert, then
return to `http://localhost:3000` and click Sign in.**

### Demo credentials

| Username | Password |
|---|---|
| `demo` | `Demo1234!` |

## Endpoints

| Service | URL |
|---|---|
| Frontend | <http://localhost:3000> |
| API (health) | <http://localhost:8080/actuator/health> |
| API (items) | <http://localhost:8080/api/items> |
| Curity admin UI | <https://localhost:6749/admin> (admin / Password1) |
| OIDC discovery | <https://localhost:8443/oauth/v2/oauth-anonymous/.well-known/openid-configuration> |

## Pushing to GitHub

```bash
cd demo-app
git init
git add .
git commit -m "Initial commit"
# Create a repo on GitHub, then:
git remote add origin git@github.com:<your-org>/demo-app.git
git push -u origin main
```

> **Note:** `curity/license.json`, generated keys, and `curity/idsvr-config-backup.xml`
> are in `.gitignore` — they will never be committed. Each developer runs `setup.sh`
> locally after cloning.

## Migrating to Railway

The Docker Compose file is the source of truth. When you're ready to deploy to
Railway, each service maps to a Railway service:
- `db` → Railway PostgreSQL plugin
- `curity` → Railway service from the `curity/idsvr` image
- `api` → Railway service built from `./api`
- `frontend` → Railway service built from `./frontend`

Environment variables can be copied directly from the `environment:` blocks in
`docker-compose.yml` to Railway's variable editor, adjusting service names to
use Railway's internal DNS.

## Project structure

```
.
├── api/                         Spring Boot resource server
│   ├── src/main/java/io/curity/demo/
│   │   ├── DemoApplication.java
│   │   ├── Item.java            JPA entity
│   │   ├── ItemRepository.java
│   │   ├── ItemController.java  GET /api/items, GET /api/items/{id}
│   │   └── SecurityConfig.java  JWT validation + CORS
│   ├── src/main/resources/application.yml
│   ├── pom.xml
│   └── Dockerfile
├── frontend/                    React SPA
│   ├── src/
│   │   ├── auth/userManager.js  oidc-client-ts setup
│   │   ├── components/ItemList.jsx
│   │   ├── App.jsx
│   │   └── main.jsx
│   ├── .env.example
│   ├── nginx.conf
│   └── Dockerfile
├── curity/
│   ├── idsvr-config-backup.xml.template   edit this, not the generated file
│   ├── license.json             ← you provide this (gitignored)
│   └── [generated files]        ← created by setup.sh (gitignored)
├── db/
│   └── init.sql                 schema + seed data
├── docker-compose.yml
├── setup.sh                     run before first `docker compose up`
└── .gitignore
```
