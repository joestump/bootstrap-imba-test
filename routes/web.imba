import { App } from '../resources/views/app'
import { Request } from '@formidablejs/framework'
import { Response } from '@formidablejs/framework'
import { Route } from '@formidablejs/framework'

# --------------------------------------------------------------------------
# Web Routes
# --------------------------------------------------------------------------
#
# Here is where you can register web routes for your application. These
# routes are loaded by the RouteServiceResolver within a group which
# is assigned the "session" middleware group.

# --------------------------------------------------------------------------
# Helper function to render the SPA with user context
# --------------------------------------------------------------------------

def render-app request\Request
	view(App, {
		formidableVersion: request.version,
		nodeVersion: process.version,
		user: request.auth!.check! ? without(request.user!, [
			'password', 'remember_token'
		]) : null
	})

# --------------------------------------------------------------------------
# Protected Routes (require authentication via Passport)
# --------------------------------------------------------------------------

Route.group { middleware: ['passport'] }, do
	Route.get('/dashboard', do(request\Request)
		render-app(request)
	)

# --------------------------------------------------------------------------
# Public Routes
# --------------------------------------------------------------------------

# Login page (public)
Route.get('/login-page', do(request\Request)
	# If already authenticated, redirect to dashboard
	if request.auth!.check!
		return Response.redirect('/dashboard')

	render-app(request)
)

# Catch-all route for SPA (must be last)
Route.get('/*', do(request\Request)
	render-app(request)
)
