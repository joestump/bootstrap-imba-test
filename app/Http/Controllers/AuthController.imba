import { Controller } from './Controller'
import { Request } from '@formidablejs/framework'
import { Response } from '@formidablejs/framework'
import { PassportServiceResolver } from '../../Resolvers/PassportServiceResolver'

export class AuthController < Controller

	# --------------------------------------------------------------------------
	# Local Authentication
	# --------------------------------------------------------------------------

	# Display login page or return login status.
	# GET /auth/login
	def login-page request\Request
		if request.auth!.check!
			return Response.redirect('/')

		# Return JSON for API consumers, or let SPA handle rendering
		{
			authenticated: false
			providers: {
				local: env('AUTH_LOCAL_ENABLED', 'true') === 'true'
				oidc: env('OIDC_ENABLED', 'false') === 'true'
				ldap: env('LDAP_ENABLED', 'false') === 'true'
			}
		}

	# Handle local login form submission.
	# POST /auth/login
	def login request\Request
		const passport = PassportServiceResolver.get-passport!

		new Promise do(resolve, reject)
			passport.authenticate('local', do(err, user, info)
				if err
					return resolve Response.json({ error: 'Authentication failed.' }, 500)

				unless user
					return resolve Response.json({
						error: info?.message or 'Invalid credentials.'
					}, 401)

				# Log in the user via Passport
				request.request.logIn user, do(login-err)
					if login-err
						return resolve Response.json({ error: 'Session creation failed.' }, 500)

					resolve Response.json({
						message: 'Login successful.'
						user: self.sanitize-user(user)
					})
			)(request.request, request.response)

	# --------------------------------------------------------------------------
	# OIDC Authentication
	# --------------------------------------------------------------------------

	# Initiate OIDC login flow.
	# GET /auth/oidc
	def oidc-login request\Request
		unless env('OIDC_ENABLED', 'false') === 'true'
			return Response.json({ error: 'OIDC authentication is not enabled.' }, 400)

		const passport = PassportServiceResolver.get-passport!
		const auth = PassportServiceResolver.authenticate('oidc', { scope: ['openid', 'profile', 'email'] })

		new Promise do(resolve)
			auth(request.request, request.response, do(err)
				if err
					resolve Response.json({ error: 'OIDC initiation failed.' }, 500)
			)

	# Handle OIDC callback after provider authentication.
	# GET /auth/oidc/callback
	def oidc-callback request\Request
		unless env('OIDC_ENABLED', 'false') === 'true'
			return Response.json({ error: 'OIDC authentication is not enabled.' }, 400)

		const passport = PassportServiceResolver.get-passport!

		new Promise do(resolve, reject)
			passport.authenticate('oidc', do(err, user, info)
				if err
					console.error 'OIDC callback error:', err
					return resolve Response.redirect('/auth/login?error=oidc_error')

				unless user
					const message = info?.message or 'oidc_failed'
					return resolve Response.redirect("/auth/login?error={encodeURIComponent(message)}")

				request.request.logIn user, do(login-err)
					if login-err
						console.error 'OIDC login error:', login-err
						return resolve Response.redirect('/auth/login?error=session_error')

					resolve Response.redirect(env('AUTH_SUCCESS_REDIRECT', '/'))
			)(request.request, request.response)

	# --------------------------------------------------------------------------
	# LDAP Authentication
	# --------------------------------------------------------------------------

	# Handle LDAP login form submission.
	# POST /auth/ldap
	def ldap-login request\Request
		unless env('LDAP_ENABLED', 'false') === 'true'
			return Response.json({ error: 'LDAP authentication is not enabled.' }, 400)

		const passport = PassportServiceResolver.get-passport!

		new Promise do(resolve, reject)
			passport.authenticate('ldap', do(err, user, info)
				if err
					console.error 'LDAP auth error:', err
					return resolve Response.json({ error: 'LDAP authentication failed.' }, 500)

				unless user
					return resolve Response.json({
						error: info?.message or 'Invalid LDAP credentials.'
					}, 401)

				request.request.logIn user, do(login-err)
					if login-err
						return resolve Response.json({ error: 'Session creation failed.' }, 500)

					resolve Response.json({
						message: 'Login successful.'
						user: self.sanitize-user(user)
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
					return resolve Response.json({ error: 'Logout failed.' }, 500)

				# Destroy the session
				if request.request.session?.destroy
					request.request.session.destroy do(session-err)
						if session-err
							console.error 'Session destroy error:', session-err

						resolve Response.json({ message: 'Logged out successfully.' })
				else
					resolve Response.json({ message: 'Logged out successfully.' })

	# Handle GET logout (redirect-based).
	# GET /auth/logout
	def logout-redirect request\Request
		new Promise do(resolve)
			request.request.logout do(err)
				if err
					console.error 'Logout error:', err

				if request.request.session?.destroy
					request.request.session.destroy do
						resolve Response.redirect(env('AUTH_LOGOUT_REDIRECT', '/auth/login'))
				else
					resolve Response.redirect(env('AUTH_LOGOUT_REDIRECT', '/auth/login'))

	# --------------------------------------------------------------------------
	# Session Status
	# --------------------------------------------------------------------------

	# Get current authentication status.
	# GET /auth/status
	def status request\Request
		if request.auth!.check!
			{
				authenticated: true
				user: self.sanitize-user(request.user!)
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
	def sanitize-user user
		const { password, remember_token, ...safe-user } = user
		safe-user
