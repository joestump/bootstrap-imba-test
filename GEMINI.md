# Project Constitution — GEMINI.md

> **Purpose:** This file is the authoritative source of truth for all architectural decisions, coding standards, and strict constraints governing this project. Any LLM agent or developer working on this codebase MUST read and adhere to this document.

---

## Meta-Instructions

### Evolution Protocol

> **IMPORTANT:** You (the LLM) are authorized and REQUIRED to update this `GEMINI.md` file whenever you make a significant architectural decision (e.g., adding a new Service Provider, changing a folder convention) or if the user issues a strict edict (e.g., "Never use X"). Do not ask for permission; treat this file as your living long-term memory.

**Examples of updates that MUST be recorded:**
- Adding a new dependency or package
- Creating a new folder convention or module structure
- Establishing a new pattern for a recurring problem
- User-issued prohibitions or mandates
- Deprecating an approach in favor of another

---

## Tech Stack

| Layer          | Technology                          | Notes                                      |
|----------------|-------------------------------------|--------------------------------------------|
| **Framework**  | Formidable (Node.js)                | Full-stack Node.js framework               |
| **Language**   | Imba                                | Used for both server and client code       |
| **Database**   | SQLite (local) + Knex/Craftsman     | Use Craftsman CLI for migrations/seeds     |
| **Auth**       | Passport.js                         | Strategies: Local, OIDC, LDAP              |
| **Testing**    | Vitest                              | Unit and integration testing               |
| **Frontend**   | Imba Router + Native Imba CSS       | No external CSS frameworks                 |

---

## Routing Architecture

### Server-Side Routes (Formidable / API)

Server-side routes are handled by **Formidable** and are responsible for:

- RESTful API endpoints (`/api/*`)
- Authentication flows (login, logout, OAuth callbacks)
- Database operations via Services/Repositories
- Server-rendered responses (if any)

**Convention:**
```
/app/routes/          # Formidable route definitions
/app/controllers/     # Request handlers
/app/services/        # Business logic
/app/repositories/    # Database access layer
```

### Client-Side Routes (Imba Router)

Client-side routes are handled by **Imba Router** and are responsible for:

- Single Page Application (SPA) navigation
- View/component rendering
- Client-side state transitions

**Convention:**
```
/resources/views/     # Imba view components
/resources/js/        # Client-side Imba application entry
```

### Route Disambiguation

| Route Type       | Handler         | Example                     |
|------------------|-----------------|-----------------------------|
| API endpoints    | Formidable      | `GET /api/users`            |
| Auth callbacks   | Formidable      | `GET /auth/oidc/callback`   |
| Page navigation  | Imba Router     | `/dashboard`, `/settings`   |
| Static assets    | Formidable      | `/assets/*`                 |

---

## Data Conventions

### Authentication Provider Schema

The `users` table supports multiple authentication providers through the following fields:

| Field               | Type     | Description                                      |
|---------------------|----------|--------------------------------------------------|
| `auth_provider`     | string   | Authentication method identifier (see below)     |
| `auth_provider_id`  | string?  | External provider's unique ID (nullable)         |
| `password`          | string?  | Hashed password (nullable, only for `local`)     |

#### `auth_provider` Values

Use **simple lowercase strings** for the `auth_provider` field. Do NOT include vendor names or suffixes.

| Value    | Description                          | `auth_provider_id` Usage                |
|----------|--------------------------------------|-----------------------------------------|
| `local`  | Username/password authentication     | `null` (not used)                       |
| `oidc`   | OpenID Connect (any OIDC provider)   | OIDC `sub` claim from ID token          |
| `ldap`   | LDAP/Active Directory                | Distinguished Name (DN) or unique UID   |

**Examples:**
```
# ✅ Correct
auth_provider: 'local'
auth_provider: 'oidc'
auth_provider: 'ldap'

# ❌ Incorrect — Do NOT use vendor-specific names
auth_provider: 'google-oidc'
auth_provider: 'azure-ad'
auth_provider: 'okta'
```

> **Rationale:** Keeping `auth_provider` generic allows the same user record to work across OIDC provider changes (e.g., migrating from Okta to Auth0) without data migration. Vendor-specific metadata should be stored elsewhere if needed.

#### Uniqueness Constraints

- `email` is unique across the entire table
- `(auth_provider, auth_provider_id)` is unique (composite constraint)

This means:
- A user cannot have the same email with different auth providers
- The same external identity cannot be linked to multiple user records

---

## Coding Standards

### Imba-Specific Standards

1. **ALWAYS use Imba native CSS** (inline styles via the `css` property or scoped `<style>` tags).
   ```imba
   # ✅ Correct
   tag my-button
       css p:2 bg:blue5 rd:md c:white
       <self> "Click me"

   # ❌ Incorrect — Do NOT use external CSS classes or Tailwind
   tag my-button
       <self.btn.btn-primary> "Click me"
   ```

2. **Prefer Imba implicit returns.** Do not use explicit `return` unless necessary for early exits or clarity.
   ```imba
   # ✅ Correct
   def get-full-name
       "{first-name} {last-name}"

   # ❌ Avoid
   def get-full-name
       return "{first-name} {last-name}"
   ```

3. **Use kebab-case** for Imba method names, variables, and tag names (Imba convention).

### Database Operations

- **ALWAYS use `node craftsman`** for all database operations:
  ```bash
  node craftsman make:migration create_users_table
  node craftsman migrate
  node craftsman make:seeder UsersSeeder
  node craftsman db:seed
  ```

- **NEVER** write raw SQL outside of migration files or repositories.

### Authentication

- All auth strategies MUST be registered via Passport.js.
- Supported strategies:
  - [x] Local (username/password)
  - [x] OIDC (OpenID Connect)
  - [x] LDAP (Active Directory)

---

## Architectural Decisions Log

> This section is automatically maintained. New decisions are appended here.

| Date       | Decision                              | Rationale                                |
|------------|---------------------------------------|------------------------------------------|
| *(init)*   | Adopt Formidable + Imba full-stack    | Unified language for client and server   |
| *(init)*   | SQLite for local development          | Zero-config, portable database           |
| *(init)*   | Vitest for testing                    | Fast, ESM-native, Vite-compatible        |
| 2026-01-08 | Multi-auth `users` table schema       | Flexible user table supporting Local, OIDC, and LDAP via `auth_provider` field |
| 2026-01-08 | Generic `auth_provider` values        | Use `'local'`, `'oidc'`, `'ldap'` — NOT vendor-specific names like `'google-oidc'` |
| 2026-01-08 | `UserRepository` with auth helpers    | Repository methods for multi-provider user lookups and creation |
| 2026-01-08 | `PassportServiceResolver` added       | Central Service Resolver for all Passport.js strategy configuration |
| 2026-01-08 | `AuthController` added                | Controller handling login, logout, and callbacks for all auth strategies |
| 2026-01-08 | Auth routes in `/routes/auth.imba`    | Dedicated route file for authentication endpoints |
| 2026-01-08 | Added passport-local, passport-openidconnect, passport-ldapauth | NPM packages for auth strategies |
| 2026-01-08 | Vitest configured for Imba                 | Configured `vitest.config.mjs` with Imba plugin, `tests/` folder structure |
| 2026-01-08 | `TestCase` helper with `actingAs`          | Test helper for auth mocking in `tests/TestCase.imba` |
| 2026-01-08 | `UserFactory` test helper                  | Factory for creating mock users in tests |

---

## Environment Variables

### Authentication Environment Variables

All authentication configuration is done via environment variables. Below is the complete reference:

#### General Auth Settings

| Variable               | Required | Default        | Description                                      |
|------------------------|----------|----------------|--------------------------------------------------|
| `AUTH_LOCAL_ENABLED`   | No       | `'true'`       | Enable/disable local (email/password) auth       |
| `AUTH_SUCCESS_REDIRECT`| No       | `'/'`          | Redirect URL after successful OIDC/external auth |
| `AUTH_LOGOUT_REDIRECT` | No       | `'/auth/login'`| Redirect URL after logout                        |
| `AUTH_LOGIN_REDIRECT`  | No       | `'/auth/login'`| Redirect URL when unauthenticated (used by middleware) |

#### OIDC (OpenID Connect) Settings

| Variable                  | Required (if OIDC enabled) | Default                | Description                          |
|---------------------------|----------------------------|------------------------|--------------------------------------|
| `OIDC_ENABLED`            | No                         | `'false'`              | Enable/disable OIDC authentication   |
| `OIDC_ISSUER`             | Yes                        | —                      | OIDC provider issuer URL             |
| `OIDC_AUTHORIZATION_URL`  | Yes                        | —                      | OIDC authorization endpoint          |
| `OIDC_TOKEN_URL`          | Yes                        | —                      | OIDC token endpoint                  |
| `OIDC_USERINFO_URL`       | Yes                        | —                      | OIDC userinfo endpoint               |
| `OIDC_CLIENT_ID`          | Yes                        | —                      | OIDC client ID                       |
| `OIDC_CLIENT_SECRET`      | Yes                        | —                      | OIDC client secret                   |
| `OIDC_CALLBACK_URL`       | No                         | `'/auth/oidc/callback'`| OIDC callback URL (must match provider config) |
| `OIDC_SCOPE`              | No                         | `'openid profile email'`| Space-separated OIDC scopes          |

#### LDAP Settings

| Variable                       | Required (if LDAP enabled) | Default                | Description                            |
|--------------------------------|----------------------------|------------------------|----------------------------------------|
| `LDAP_ENABLED`                 | No                         | `'false'`              | Enable/disable LDAP authentication     |
| `LDAP_URL`                     | Yes                        | —                      | LDAP server URL (e.g., `ldap://localhost:389`) |
| `LDAP_BIND_DN`                 | Yes                        | —                      | DN to bind for LDAP searches           |
| `LDAP_BIND_PASSWORD`           | Yes                        | —                      | Password for bind DN                   |
| `LDAP_SEARCH_BASE`             | Yes                        | —                      | Base DN for user searches              |
| `LDAP_SEARCH_FILTER`           | No                         | `'(uid={{username}})'` | LDAP search filter                     |
| `LDAP_SEARCH_ATTRIBUTES`       | No                         | `'uid,mail,cn,displayName'` | Comma-separated attributes to retrieve |
| `LDAP_TLS_REJECT_UNAUTHORIZED` | No                         | `'true'`               | Reject unauthorized TLS certificates   |
| `LDAP_USERNAME_FIELD`          | No                         | `'username'`           | Form field name for LDAP username      |
| `LDAP_PASSWORD_FIELD`          | No                         | `'password'`           | Form field name for LDAP password      |

### Example `.env` Configuration

```bash
# Local Auth (enabled by default)
AUTH_LOCAL_ENABLED=true

# OIDC (e.g., Auth0, Okta, Azure AD)
OIDC_ENABLED=true
OIDC_ISSUER=https://your-tenant.auth0.com/
OIDC_AUTHORIZATION_URL=https://your-tenant.auth0.com/authorize
OIDC_TOKEN_URL=https://your-tenant.auth0.com/oauth/token
OIDC_USERINFO_URL=https://your-tenant.auth0.com/userinfo
OIDC_CLIENT_ID=your-client-id
OIDC_CLIENT_SECRET=your-client-secret
OIDC_CALLBACK_URL=http://localhost:3000/auth/oidc/callback

# LDAP (e.g., Active Directory)
LDAP_ENABLED=true
LDAP_URL=ldap://ldap.example.com:389
LDAP_BIND_DN=cn=admin,dc=example,dc=com
LDAP_BIND_PASSWORD=admin-password
LDAP_SEARCH_BASE=ou=users,dc=example,dc=com
LDAP_SEARCH_FILTER=(mail={{username}})
```

---

## Prohibitions & Edicts

> User-issued mandates that MUST NOT be violated.

*(None yet — this section will be populated as edicts are issued.)*

---

## Future Considerations

> Items under consideration but not yet decided.

- Production database strategy (PostgreSQL migration path)
- Session storage (in-memory vs. Redis vs. SQLite)
- Deployment target (Docker, serverless, VPS)
- Multi-factor authentication (MFA/2FA)
- Account linking (allowing a user to link multiple auth providers)

---

## Authentication Routes Reference

| Method | Path                  | Handler                     | Description                         |
|--------|-----------------------|-----------------------------|-------------------------------------|
| GET    | `/auth/login`         | `AuthController.login-page` | Login page / available providers    |
| POST   | `/auth/login`         | `AuthController.login`      | Local email/password login          |
| GET    | `/auth/oidc`          | `AuthController.oidc-login` | Initiate OIDC flow                  |
| GET    | `/auth/oidc/callback` | `AuthController.oidc-callback` | OIDC provider callback           |
| POST   | `/auth/ldap`          | `AuthController.ldap-login` | LDAP authentication                 |
| POST   | `/auth/logout`        | `AuthController.logout`     | Logout (API)                        |
| GET    | `/auth/logout`        | `AuthController.logout-redirect` | Logout (redirect)              |
| GET    | `/auth/status`        | `AuthController.status`     | Get current auth status             |

---

## Middleware Reference

### `PassportAuth` Middleware

The `PassportAuth` middleware protects routes by verifying the user is authenticated via Passport.js.

**Alias:** `'passport'`

**Usage in routes:**
```imba
# Protect a single route
Route.get('/dashboard', [DashboardController, 'index']).middleware(['passport'])

# Protect a group of routes
Route.group { middleware: ['passport'] }, do
    Route.get('/settings', [SettingsController, 'index'])
    Route.post('/settings', [SettingsController, 'update'])
```

**Behavior:**
- **Authenticated:** Proceeds to the route handler
- **Unauthenticated API request:** Returns `401 JSON` response
- **Unauthenticated browser request:** Redirects to `AUTH_LOGIN_REDIRECT` (default: `/auth/login`)

---

## Testing

### Running Tests

Run all tests with:
```bash
npm test
```

Run tests in watch mode during development:
```bash
npm run test:watch
```

### Test Directory Structure

```
/tests/
  setup.imba           # Global test setup (runs before all tests)
  TestCase.imba        # Test helper with actingAs, HTTP helpers
  Feature/             # Feature/integration tests
    AuthTest.test.imba # Authentication tests
```

### Writing Tests

Tests are written in Imba using Vitest. All test files must use the `.test.imba` extension.

**Basic Test Structure:**
```imba
import { describe, it, expect, beforeEach } from 'vitest'
import { UserFactory } from '../TestCase.imba'

describe 'My Feature', do
    beforeEach do
        UserFactory.reset!

    it 'does something', do
        const user = UserFactory.createLocal!
        expect(user.auth_provider).toBe('local')
```

### Using the `actingAs` Helper

The `TestCase` helper provides an `actingAs` method for mocking authenticated users in tests.

**Usage:**
```imba
import { TestCase, UserFactory } from '../TestCase.imba'

describe 'Protected Routes', do
    const tc = new TestCase

    beforeAll do await tc.setup!
    afterAll do await tc.teardown!
    beforeEach do tc.reset!

    it 'allows authenticated users', do
        # Mock authentication as a local user
        tc.actingAs({
            id: 1
            email: 'admin@example.com'
            name: 'Admin User'
        })

        const res = await tc.get('/dashboard')
        expect(res.status).toBe(200)

    it 'allows OIDC users', do
        # Mock authentication as an OIDC user
        tc.actingAs({
            id: 2
            email: 'oidc@example.com'
            name: 'OIDC User'
            auth_provider: 'oidc'
            auth_provider_id: 'oidc-sub-12345'
        })

        const res = await tc.get('/protected')
        expect(res.status).toBe(200)
```

### Using `UserFactory`

The `UserFactory` creates mock user objects for testing. It supports all three auth providers:

```imba
import { UserFactory } from '../TestCase.imba'

# Create a local user
const local-user = UserFactory.createLocal!
const local-user-custom = UserFactory.createLocal({ email: 'custom@test.com' })

# Create an OIDC user
const oidc-user = UserFactory.createOidc!
const oidc-user-custom = UserFactory.createOidc({ auth_provider_id: 'google|123' })

# Create an LDAP user
const ldap-user = UserFactory.createLdap!

# Reset counter between tests
UserFactory.reset!
```

### Test Conventions

1. **File naming:** Use `*.test.imba` suffix for all test files
2. **Imports:** Always include `.imba` extension when importing local Imba files
3. **Reset state:** Call `UserFactory.reset!` in `beforeEach` to ensure clean state
4. **Async tests:** Use `async/await` for any tests that involve promises

---

*Last Updated: 2026-01-08*