# Bootstrap Imba Test

A full-stack application built with the [Formidable](https://formidablejs.org/) framework and [Imba](https://imba.io/) language.

## 🛠 Tech Stack

| Component | Technology | Description |
|-----------|------------|-------------|
| **Framework** | Formidable | Full-stack Node.js framework |
| **Language** | Imba | Unified language for server and client |
| **Database** | SQLite | Local database (managed via Craftsman) |
| **Auth** | Passport.js | Local, OIDC, and LDAP strategies |
| **Frontend** | Imba | Imba Router & Native Imba CSS |
| **Testing** | Vitest | Unit and integration testing |

## 🚀 Local Development

### Prerequisites

- Node.js (LTS recommended)
- npm

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd bootstrap-imba-test
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

### Configuration

1. Create a `.env` file in the project root.
2. Generate an application key:
   ```bash
   node craftsman key:generate
   ```
3. Configure your environment variables. Refer to [GEMINI.md](./GEMINI.md#environment-variables) for detailed authentication configuration (OIDC, LDAP, etc.).

   **Minimal `.env` example:**
   ```ini
   APP_NAME=Formidable
   APP_ENV=local
   APP_DEBUG=true
   APP_URL=http://localhost:3000
   
   DB_CONNECTION=sqlite
   DB_DATABASE=database/database.sqlite
   
   AUTH_LOCAL_ENABLED=true
   ```

### Database Setup

Initialize the SQLite database and run migrations:

```bash
# Run migrations to create tables
node craftsman migrate

# Seed the database with initial data (optional)
node craftsman db:seed
```

### Running the Application

**Development Mode:**
Starts the server with hot-reloading for both server and client code.
```bash
npm run dev
```
The application will be available at `http://localhost:3000`.

**Production Mode:**
Build and serve the application for production use.
```bash
npm run build
npm run serve
```

### Testing

Run the test suite using Vitest:

```bash
# Run all tests once
npm test

# Run tests in watch mode
npm run test:watch
```

## 📚 Project Constitution

For architectural decisions, coding standards, and strict project constraints, strictly adhere to **[GEMINI.md](./GEMINI.md)**.
