import { ServiceResolver } from '@formidablejs/framework'
import { Hash } from '@formidablejs/framework'
import { UserRepository } from '../Repositories/UserRepository'
import passport from 'passport'
import { Strategy as LocalStrategy } from 'passport-local'
import { Strategy as OIDCStrategy } from 'passport-openidconnect'
import { Strategy as LDAPStrategy } from 'passport-ldapauth'

export class PassportServiceResolver < ServiceResolver

	# --------------------------------------------------------------------------
	# Passport Middleware
	# --------------------------------------------------------------------------

	def register
		# Register Passport middleware with the application.
		# This ensures passport.initialize() and passport.session() are called.
		app.use passport.initialize!
		app.use passport.session!

	# --------------------------------------------------------------------------
	# Configuration
	# --------------------------------------------------------------------------

	# Check if a strategy is enabled via environment variables.
	def is-local-enabled
		env('AUTH_LOCAL_ENABLED', 'true') === 'true'

	def is-oidc-enabled
		env('OIDC_ENABLED', 'false') === 'true'

	def is-ldap-enabled
		env('LDAP_ENABLED', 'false') === 'true'

	# --------------------------------------------------------------------------
	# Service Resolver Lifecycle
	# --------------------------------------------------------------------------

	def boot
		self.configure-serialization!
		self.configure-local-strategy! if is-local-enabled!
		self.configure-oidc-strategy! if is-oidc-enabled!
		self.configure-ldap-strategy! if is-ldap-enabled!

		console.log '[Passport] Initialized with strategies:', self.get-enabled-strategies!.join(', ')
		self

	def get-enabled-strategies
		const strategies = []
		strategies.push('local') if is-local-enabled!
		strategies.push('oidc') if is-oidc-enabled!
		strategies.push('ldap') if is-ldap-enabled!
		strategies

	# --------------------------------------------------------------------------
	# Passport Serialization
	# --------------------------------------------------------------------------

	def configure-serialization
		# Serialize user to session (store user ID)
		passport.serializeUser do(user, done)
			done(null, user.id)

		# Deserialize user from session (retrieve full user)
		passport.deserializeUser do(id, done)
			try
				const user-repo = new UserRepository
				const user = await user-repo.find(id)
				done(null, user)
			catch error
				done(error, null)

	# --------------------------------------------------------------------------
	# Local Strategy (Username/Password)
	# --------------------------------------------------------------------------

	def configure-local-strategy
		const strategy = new LocalStrategy(
			{
				usernameField: 'email'
				passwordField: 'password'
			}
			do(email, password, done)
				try
					const user-repo = new UserRepository
					const user = await user-repo.find-by-email-and-provider(email, 'local')

					unless user
						return done(null, false, { message: 'Invalid email or password.' })

					const is-valid = await Hash.check(password, user.password)

					unless is-valid
						return done(null, false, { message: 'Invalid email or password.' })

					done(null, user)
				catch error
					done(error)
		)

		passport.use('local', strategy)

	# --------------------------------------------------------------------------
	# OIDC Strategy (OpenID Connect)
	# --------------------------------------------------------------------------

	def configure-oidc-strategy
		const oidc-config = {
			issuer: env('OIDC_ISSUER')
			authorizationURL: env('OIDC_AUTHORIZATION_URL')
			tokenURL: env('OIDC_TOKEN_URL')
			userInfoURL: env('OIDC_USERINFO_URL')
			clientID: env('OIDC_CLIENT_ID')
			clientSecret: env('OIDC_CLIENT_SECRET')
			callbackURL: env('OIDC_CALLBACK_URL', '/auth/oidc/callback')
			scope: env('OIDC_SCOPE', 'openid profile email').split(' ')
		}

		const strategy = new OIDCStrategy(
			oidc-config
			do(issuer, profile, done)
				self.handle-oidc-profile(profile, done)
		)

		passport.use('oidc', strategy)

	def handle-oidc-profile profile, done
		try
			const user-repo = new UserRepository
			const provider-id = profile.id
			const email = profile.emails?[0]?.value or profile._json?.email

			unless email
				return done(null, false, { message: 'No email provided by OIDC provider.' })

			# First, try to find by provider ID
			let user = await user-repo.find-by-provider('oidc', provider-id)

			if user
				return done(null, user)

			# Check if email exists for any provider
			const existing-user = await user-repo.find-by-email(email)

			if existing-user
				# Email already exists with a different provider
				return done(null, false, {
					message: 'An account with this email already exists using a different login method.'
				})

			# Create new OIDC user
			user = await user-repo.create-oidc-user({
				email: email
				name: profile.displayName or "{profile.name?.givenName} {profile.name?.familyName}".trim!
				email_verified_at: new Date!
			}, provider-id)

			done(null, user)
		catch error
			done(error)

	# --------------------------------------------------------------------------
	# LDAP Strategy (Active Directory)
	# --------------------------------------------------------------------------

	def configure-ldap-strategy
		const ldap-config = {
			server: {
				url: env('LDAP_URL')
				bindDN: env('LDAP_BIND_DN')
				bindCredentials: env('LDAP_BIND_PASSWORD')
				searchBase: env('LDAP_SEARCH_BASE')
				searchFilter: env('LDAP_SEARCH_FILTER', '(uid={{username}})')
				searchAttributes: env('LDAP_SEARCH_ATTRIBUTES', 'uid,mail,cn,displayName').split(',')
				tlsOptions: {
					rejectUnauthorized: env('LDAP_TLS_REJECT_UNAUTHORIZED', 'true') === 'true'
				}
			}
			usernameField: env('LDAP_USERNAME_FIELD', 'username')
			passwordField: env('LDAP_PASSWORD_FIELD', 'password')
		}

		const strategy = new LDAPStrategy(
			ldap-config
			do(ldap-user, done)
				self.handle-ldap-user(ldap-user, done)
		)

		passport.use('ldap', strategy)

	def handle-ldap-user ldap-user, done
		try
			const user-repo = new UserRepository

			# The DN (Distinguished Name) is used as the provider ID
			const provider-id = ldap-user.dn or ldap-user.uid
			const email = ldap-user.mail or ldap-user.email
			const name = ldap-user.displayName or ldap-user.cn or ldap-user.uid

			unless email
				return done(null, false, { message: 'No email found in LDAP response.' })

			# First, try to find by provider ID
			let user = await user-repo.find-by-provider('ldap', provider-id)

			if user
				return done(null, user)

			# Check if email exists for any provider
			const existing-user = await user-repo.find-by-email(email)

			if existing-user
				return done(null, false, {
					message: 'An account with this email already exists using a different login method.'
				})

			# Create new LDAP user
			user = await user-repo.create-ldap-user({
				email: email
				name: name
				email_verified_at: new Date!
			}, provider-id)

			done(null, user)
		catch error
			done(error)

	# --------------------------------------------------------------------------
	# Utility Methods
	# --------------------------------------------------------------------------

	# Get the passport instance for use in routes/middleware.
	static def get-passport
		passport

	# Authenticate with a specific strategy.
	static def authenticate strategy, options = {}
		passport.authenticate(strategy, options)
