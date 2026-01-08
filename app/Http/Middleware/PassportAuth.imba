import { Middleware } from '@formidablejs/framework'
import { Request } from '@formidablejs/framework'
import { Response } from '@formidablejs/framework'

export class PassportAuth < Middleware

	# --------------------------------------------------------------------------
	# Passport Authentication Middleware
	# --------------------------------------------------------------------------
	#
	# This middleware checks if the user is authenticated via Passport.js.
	# Use this middleware to protect routes that require authentication.
	#
	# Usage in routes:
	#   Route.get('/protected', [MyController, 'action']).middleware([PassportAuth])

	def handle request\Request, next\Function
		# Check if user is authenticated via Passport
		if request.request.isAuthenticated and request.request.isAuthenticated!
			return next(request)

		# Check if this is an API request (expects JSON)
		const accepts-json = request.header('Accept')?.includes('application/json')
		const is-xhr = request.header('X-Requested-With') === 'XMLHttpRequest'

		if accepts-json or is-xhr
			# Return JSON error for API requests
			return Response.json({ error: 'Unauthorized. Please log in.' }, 401)

		# Redirect to login page for browser requests
		Response.redirect(env('AUTH_LOGIN_REDIRECT', '/auth/login'))
