import { env } from '@formidablejs/framework'

export class TestAuthMiddleware

	def handle request, next
		# Only run in testing environment
		return next(request) unless env('NODE_ENV') === 'testing'

		# Check for mock user header
		const mock-user-json = request.header('X-Test-Auth-User')

		if mock-user-json
			try
				const user = JSON.parse(mock-user-json)
				
				# Log the user in via Passport
				# We use a custom login function or modify the request directly
				# Since we are using Passport, we should try to use its login method
				# But request.request.login is async and provided by passport middleware
				
				const req = request.request
				
				if req.login
					await new Promise do(resolve, reject)
						req.login(user, do(err)
							if err then reject(err) else resolve!
						)
				else
					# Fallback if login method missing (shouldn't happen if InitPassport runs first)
					req.user = user
			catch e
				console.error "Failed to mock auth user", e

		next(request)
