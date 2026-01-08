export class TestAuthMiddleware

	# --------------------------------------------------------------------------
	# Test Authentication Middleware
	# --------------------------------------------------------------------------
	#
	# This middleware mocks Passport.js authentication for testing purposes.
	# It only activates when NODE_ENV === 'testing'.
	#
	# Formidable middleware signature: handle(request, reply, params)
	# Note: There is no 'next' callback - just return to continue to next middleware.

	def handle request, reply, params = []
		# Only run in testing environment
		if process.env.NODE_ENV !== 'testing'
			return

		# Check for mock user header
		const mockUserJson = request.header('X-Test-Auth-User')

		if mockUserJson
			try
				const user = JSON.parse(mockUserJson)
				# Directly set user on request object
				request.request.user = user
			catch parseError
				console.error('[TestAuthMiddleware] Failed to parse X-Test-Auth-User header:', parseError)

		# Ensure Passport methods exist (mock them if missing)
		const req = request.request

		if !req.isAuthenticated
			req.isAuthenticated = do
				!!req.user

		if !req.isUnauthenticated
			req.isUnauthenticated = do
				!req.user

		if !req.login
			req.login = do(u, cb)
				req.user = u
				cb(null) if cb

		if !req.logout
			req.logout = do(cb)
				req.user = null
				cb(null) if cb

		# Mock session object if not present (needed for logout tests)
		if !req.session
			req.session = {
				destroy: do(cb)
					if cb
						cb(null)
			}

		# Return nothing to continue to next middleware
		return
