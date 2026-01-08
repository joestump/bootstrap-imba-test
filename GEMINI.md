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
- Supported strategies (to be implemented):
  - [x] Local (username/password)
  - [ ] OIDC (OpenID Connect)
  - [ ] LDAP (Active Directory)

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

---

*Last Updated: 2026-01-08*