import { Request } from '@formidablejs/framework'
import { Response } from '@formidablejs/framework'
import { env } from '@formidablejs/framework'

# Create a Response instance for JSON responses
# This avoids minification issues with static method calls
const JsonResponse = new Response()

export class PassportAuth

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
		const acceptHeader = request.header('Accept')
		const acceptsJson = acceptHeader and acceptHeader.includes('application/json')
		const isXhr = request.header('X-Requested-With') === 'XMLHttpRequest'

		if acceptsJson or isXhr
			# Return JSON error for API requests
			return JsonResponse.json({ error: 'Unauthorized. Please log in.' }, 401)

		# Redirect to login page for browser requests
		Response.redirect(env('AUTH_LOGIN_REDIRECT', '/auth/login'))
