import passport from 'passport'

export class InitPassport

	def handle request, next
		const req = request.request.raw
		const res = request.reply.raw

		# Ensure session exists (mock it if testing/missing) to prevent passport crash
		if request.request.session
			req.session = request.request.session
		else
			req.session = {}

		# Ensure body and query are available on raw request
		req.body = request.request.body if request.request.body
		req.query = request.request.query if request.request.query

		const init = passport.initialize!
		const sess = passport.session!

		await new Promise do(resolve, reject)
			init(req, res, do(err)
				return reject(err) if err
				sess(req, res, do(err)
					return reject(err) if err
					resolve!
				)
			)

		# Proxy Passport methods to Fastify request
		# request.request.logIn = req.logIn
		# request.request.login = req.login
		# request.request.logOut = req.logOut
		# request.request.logout = req.logout
		# request.request.isAuthenticated = req.isAuthenticated
		# request.request.isUnauthenticated = req.isUnauthenticated
		# request.request.user = req.user

		return next(request)
