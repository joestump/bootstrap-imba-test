import { Controller } from './Controller'
import { Request } from '@formidablejs/framework'
import { Response } from '@formidablejs/framework'
import { PassportServiceResolver } from '../../Resolvers/PassportServiceResolver'

# Create a Response instance for JSON responses
# This avoids minification issues with static method calls
const JsonResponse = new Response()

export class AuthController < Controller

	# --------------------------------------------------------------------------
	# Local Authentication
	# --------------------------------------------------------------------------

	# Display login page or return login status.
	# GET /auth/login
	def loginPage request\Request
		if request.auth!.check!
			return Response.redirect('/')

		# Return JSON for API consumers, or let SPA handle rendering
		{
			authenticated: false
			providers: {
				local: (process.env.AUTH_LOCAL_ENABLED || 'true') === 'true'
				oidc: (process.env.OIDC_ENABLED || 'false') === 'true'
				ldap: (process.env.LDAP_ENABLED || 'false') === 'true'
			}
		}

	# Handle local login form submission.
	# POST /auth/login
	def login request\Request
		const passport = PassportServiceResolver.getPassport!

		new Promise do(resolve, reject)
			passport.authenticate('local', do(err, user, info)
				if err
					return resolve JsonResponse.json({ error: 'Authentication failed.' }, 500)

				unless user
					const errorMessage = (info and info.message) or 'Invalid credentials.'
					return resolve JsonResponse.json({ error: errorMessage }, 401)

				# Log in the user via Passport
				request.request.logIn user, do(loginErr)
					if loginErr
						return resolve JsonResponse.json({ error: 'Session creation failed.' }, 500)

					resolve JsonResponse.json({
						message: 'Login successful.'
						user: self.sanitizeUser(user)
					})
			)(request.request, request.response)

	# --------------------------------------------------------------------------
	# OIDC Authentication
	# --------------------------------------------------------------------------

	# Initiate OIDC login flow.
	# GET /auth/oidc
	def oidcLogin request\Request
		unless (process.env.OIDC_ENABLED || 'false') === 'true'
			return JsonResponse.json({ error: 'OIDC authentication is not enabled.' }, 400)

		const passport = PassportServiceResolver.getPassport!
		const auth = PassportServiceResolver.authenticate('oidc', { scope: ['openid', 'profile', 'email'] })

		new Promise do(resolve)
			auth(request.request, request.response, do(err)
				if err
					resolve JsonResponse.json({ error: 'OIDC initiation failed.' }, 500)
			)

	# Handle OIDC callback after provider authentication.
	# GET /auth/oidc/callback
	def oidcCallback request\Request
		unless (process.env.OIDC_ENABLED || 'false') === 'true'
			return JsonResponse.json({ error: 'OIDC authentication is not enabled.' }, 400)

		const passport = PassportServiceResolver.getPassport!

		new Promise do(resolve, reject)
			passport.authenticate('oidc', do(err, user, info)
				if err
					console.error 'OIDC callback error:', err
					return resolve Response.redirect('/auth/login?error=oidc_error')

				unless user
					const message = (info and info.message) or 'oidc_failed'
					return resolve Response.redirect("/auth/login?error={encodeURIComponent(message)}")

				request.request.logIn user, do(loginErr)
					if loginErr
						console.error 'OIDC login error:', loginErr
						return resolve Response.redirect('/auth/login?error=session_error')

					resolve Response.redirect(process.env.AUTH_SUCCESS_REDIRECT || '/')
			)(request.request, request.response)

	# --------------------------------------------------------------------------
	# LDAP Authentication
	# --------------------------------------------------------------------------

	# Handle LDAP login form submission.
	# POST /auth/ldap
	def ldapLogin request\Request
		unless (process.env.LDAP_ENABLED || 'false') === 'true'
			return JsonResponse.json({ error: 'LDAP authentication is not enabled.' }, 400)

		const passport = PassportServiceResolver.getPassport!

		new Promise do(resolve, reject)
			passport.authenticate('ldap', do(err, user, info)
				if err
					console.error 'LDAP auth error:', err
					return resolve JsonResponse.json({ error: 'LDAP authentication failed.' }, 500)

				unless user
					const errorMessage = (info and info.message) or 'Invalid LDAP credentials.'
					return resolve JsonResponse.json({ error: errorMessage }, 401)

				request.request.logIn user, do(loginErr)
					if loginErr
						return resolve JsonResponse.json({ error: 'Session creation failed.' }, 500)

					resolve JsonResponse.json({
						message: 'Login successful.'
						user: self.sanitizeUser(user)
					})
			)(request.request, request.response)

	# --------------------------------------------------------------------------
	# Logout
	# --------------------------------------------------------------------------

	# Log out the current user.
	# POST /auth/logout
	def logout request\Request
		new Promise do(resolve)
			request.request.logout do(err)
				if err
					console.error 'Logout error:', err
					return resolve JsonResponse.json({ error: 'Logout failed.' }, 500)

				# Destroy the session
				if request.request.session and request.request.session.destroy
					request.request.session.destroy do(sessionErr)
						if sessionErr
							console.error 'Session destroy error:', sessionErr

						resolve JsonResponse.json({ message: 'Logged out successfully.' })
				else
					resolve JsonResponse.json({ message: 'Logged out successfully.' })

	# Handle GET logout (redirect-based).
	# GET /auth/logout
	def logoutRedirect request\Request
		new Promise do(resolve)
			request.request.logout do(err)
				if err
					console.error 'Logout error:', err

				if request.request.session and request.request.session.destroy
					request.request.session.destroy do
						resolve Response.redirect(process.env.AUTH_LOGOUT_REDIRECT || '/auth/login')
				else
					resolve Response.redirect(process.env.AUTH_LOGOUT_REDIRECT || '/auth/login')

	# --------------------------------------------------------------------------
	# Session Status
	# --------------------------------------------------------------------------

	# Get current authentication status.
	# GET /auth/status
	def status request\Request
		if request.auth!.check!
			{
				authenticated: true
				user: self.sanitizeUser(request.user!)
			}
		else
			{
				authenticated: false
				user: null
			}

	# --------------------------------------------------------------------------
	# Utility Methods
	# --------------------------------------------------------------------------

	# Remove sensitive fields from user object.
	def sanitizeUser user
		const { password, remember_token, ...safeUser } = user
		safeUser
