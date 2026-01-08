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
		# app.use passport.initialize!
		# app.use passport.session!

	# --------------------------------------------------------------------------
	# Configuration
	# --------------------------------------------------------------------------

	# Check if a strategy is enabled via environment variables.
	def isLocalEnabled
		(process.env.AUTH_LOCAL_ENABLED || 'true') === 'true'

	def isOidcEnabled
		(process.env.OIDC_ENABLED || 'false') === 'true'

	def isLdapEnabled
		(process.env.LDAP_ENABLED || 'false') === 'true'

	# --------------------------------------------------------------------------
	# Service Resolver Lifecycle
	# --------------------------------------------------------------------------

	def boot
		self.configureSerialization!
		self.configureLocalStrategy! if isLocalEnabled!
		self.configureOidcStrategy! if isOidcEnabled!
		self.configureLdapStrategy! if isLdapEnabled!

		console.log '[Passport] Initialized with strategies:', self.getEnabledStrategies!.join(', ')
		self

	def getEnabledStrategies
		const strategies = []
		strategies.push('local') if isLocalEnabled!
		strategies.push('oidc') if isOidcEnabled!
		strategies.push('ldap') if isLdapEnabled!
		strategies

	# --------------------------------------------------------------------------
	# Passport Serialization
	# --------------------------------------------------------------------------

	def configureSerialization
		# Serialize user to session (store user ID)
		passport.serializeUser do(user, done)
			done(null, user.id)

		# Deserialize user from session (retrieve full user)
		passport.deserializeUser do(id, done)
			try
				const userRepo = new UserRepository
				const user = await userRepo.find(id)
				done(null, user)
			catch error
				done(error, null)

	# --------------------------------------------------------------------------
	# Local Strategy (Username/Password)
	# --------------------------------------------------------------------------

	def configureLocalStrategy
		const strategy = new LocalStrategy(
			{
				usernameField: 'email'
				passwordField: 'password'
			}
			do(email, password, done)
				try
					const userRepo = new UserRepository
					const user = await userRepo.findByEmailAndProvider(email, 'local')

					unless user
						return done(null, false, { message: 'Invalid email or password.' })

					const isValid = await Hash.check(password, user.password)

					unless isValid
						return done(null, false, { message: 'Invalid email or password.' })

					done(null, user)
				catch error
					done(error)
		)

		passport.use('local', strategy)

	# --------------------------------------------------------------------------
	# OIDC Strategy (OpenID Connect)
	# --------------------------------------------------------------------------

	def configureOidcStrategy
		const oidcConfig = {
			issuer: process.env.OIDC_ISSUER
			authorizationURL: process.env.OIDC_AUTHORIZATION_URL
			tokenURL: process.env.OIDC_TOKEN_URL
			userInfoURL: process.env.OIDC_USERINFO_URL
			clientID: process.env.OIDC_CLIENT_ID
			clientSecret: process.env.OIDC_CLIENT_SECRET
			callbackURL: process.env.OIDC_CALLBACK_URL || '/auth/oidc/callback'
			scope: (process.env.OIDC_SCOPE || 'openid profile email').split(' ')
		}

		const strategy = new OIDCStrategy(
			oidcConfig
			do(issuer, profile, done)
				self.handleOidcProfile(profile, done)
		)

		passport.use('oidc', strategy)

	def handleOidcProfile profile, done
		try
			const userRepo = new UserRepository
			const providerId = profile.id
			const email = profile.emails?[0]?.value or profile._json?.email

			unless email
				return done(null, false, { message: 'No email provided by OIDC provider.' })

			# First, try to find by provider ID
			let user = await userRepo.findByProvider('oidc', providerId)

			if user
				return done(null, user)

			# Check if email exists for any provider
			const existingUser = await userRepo.findByEmail(email)

			if existingUser
				# Email already exists with a different provider
				return done(null, false, {
					message: 'An account with this email already exists using a different login method.'
				})

			# Create new OIDC user
			user = await userRepo.createOidcUser({
				email: email
				name: profile.displayName or "{profile.name?.givenName} {profile.name?.familyName}".trim!
				email_verified_at: new Date!
			}, providerId)

			done(null, user)
		catch error
			done(error)

	# --------------------------------------------------------------------------
	# LDAP Strategy (Active Directory)
	# --------------------------------------------------------------------------

	def configureLdapStrategy
		const ldapConfig = {
			server: {
				url: process.env.LDAP_URL
				bindDN: process.env.LDAP_BIND_DN
				bindCredentials: process.env.LDAP_BIND_PASSWORD
				searchBase: process.env.LDAP_SEARCH_BASE
				searchFilter: process.env.LDAP_SEARCH_FILTER || '(uid={{username}})'
				searchAttributes: (process.env.LDAP_SEARCH_ATTRIBUTES || 'uid,mail,cn,displayName').split(',')
				tlsOptions: {
					rejectUnauthorized: (process.env.LDAP_TLS_REJECT_UNAUTHORIZED || 'true') === 'true'
				}
			}
			usernameField: process.env.LDAP_USERNAME_FIELD || 'username'
			passwordField: process.env.LDAP_PASSWORD_FIELD || 'password'
		}

		const strategy = new LDAPStrategy(
			ldapConfig
			do(ldapUser, done)
				self.handleLdapUser(ldapUser, done)
		)

		passport.use('ldap', strategy)

	def handleLdapUser ldapUser, done
		try
			const userRepo = new UserRepository

			# The DN (Distinguished Name) is used as the provider ID
			const providerId = ldapUser.dn or ldapUser.uid
			const email = ldapUser.mail or ldapUser.email
			const name = ldapUser.displayName or ldapUser.cn or ldapUser.uid

			unless email
				return done(null, false, { message: 'No email found in LDAP response.' })

			# First, try to find by provider ID
			let user = await userRepo.findByProvider('ldap', providerId)

			if user
				return done(null, user)

			# Check if email exists for any provider
			const existingUser = await userRepo.findByEmail(email)

			if existingUser
				return done(null, false, {
					message: 'An account with this email already exists using a different login method.'
				})

			# Create new LDAP user
			user = await userRepo.createLdapUser({
				email: email
				name: name
				email_verified_at: new Date!
			}, providerId)

			done(null, user)
		catch error
			done(error)

	# --------------------------------------------------------------------------
	# Utility Methods
	# --------------------------------------------------------------------------

	# Get the passport instance for use in routes/middleware.
	static def getPassport
		passport

	# Authenticate with a specific strategy.
	static def authenticate strategy, options = {}
		passport.authenticate(strategy, options)
