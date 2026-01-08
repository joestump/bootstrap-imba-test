import { Route } from '@formidablejs/framework'
import { AuthController } from '../app/Http/Controllers/AuthController'

# --------------------------------------------------------------------------
# Authentication Routes
# --------------------------------------------------------------------------
#
# These routes handle all authentication flows for the application.
# Supports Local (username/password), OIDC, and LDAP strategies.

# --------------------------------------------------------------------------
# Login Page & Status
# --------------------------------------------------------------------------

# Display login page or return available providers.
Route.get('/auth/login', [AuthController, 'loginPage'])

# Get current authentication status.
Route.get('/auth/status', [AuthController, 'status'])

# --------------------------------------------------------------------------
# Local Authentication
# --------------------------------------------------------------------------

# Handle local login form submission.
Route.post('/auth/login', [AuthController, 'login'])

# --------------------------------------------------------------------------
# OIDC Authentication
# --------------------------------------------------------------------------

# Initiate OIDC login flow (redirects to provider).
Route.get('/auth/oidc', [AuthController, 'oidcLogin'])

# Handle OIDC callback after provider authentication.
Route.get('/auth/oidc/callback', [AuthController, 'oidcCallback'])

# --------------------------------------------------------------------------
# LDAP Authentication
# --------------------------------------------------------------------------

# Handle LDAP login form submission.
Route.post('/auth/ldap', [AuthController, 'ldapLogin'])

# --------------------------------------------------------------------------
# Logout
# --------------------------------------------------------------------------

# Log out via POST (API-friendly).
Route.post('/auth/logout', [AuthController, 'logout'])

# Log out via GET (redirect-based for links).
Route.get('/auth/logout', [AuthController, 'logoutRedirect'])
