import { Repository } from '@formidablejs/framework'

export class UserRepository < Repository

	# The table associated with the repository.
	get tableName\string
		'users'

	# Context reference.
	static get context\string
		'UserRepository'

	# --------------------------------------------------------------------------
	# Query Methods
	# --------------------------------------------------------------------------

	# Find a user by their email address.
	def findByEmail email\string
		self.table.where('email', email).first!

	# Find a user by their auth provider and provider ID.
	# Use this for OIDC/LDAP lookups where we match on external identity.
	def findByProvider provider\string, providerId\string
		self.table
			.where('auth_provider', provider)
			.where('auth_provider_id', providerId)
			.first!

	# Find a user by email and specific auth provider.
	# Useful when the same email might exist across different providers.
	def findByEmailAndProvider email\string, provider\string
		self.table
			.where('email', email)
			.where('auth_provider', provider)
			.first!

	# --------------------------------------------------------------------------
	# Creation Methods
	# --------------------------------------------------------------------------

	# Create a new local user (username/password auth).
	def createLocalUser data\object
		const userData = {
			...data
			auth_provider: 'local'
			auth_provider_id: null
		}
		self.create(userData)

	# Create a new OIDC user.
	# The providerId should be the 'sub' claim from the OIDC token.
	def createOidcUser data\object, providerId\string
		const userData = {
			...data
			auth_provider: 'oidc'
			auth_provider_id: providerId
			password: null
		}
		self.create(userData)

	# Create a new LDAP user.
	# The providerId should be the DN or unique identifier from LDAP.
	def createLdapUser data\object, providerId\string
		const userData = {
			...data
			auth_provider: 'ldap'
			auth_provider_id: providerId
			password: null
		}
		self.create(userData)

	# --------------------------------------------------------------------------
	# Update Methods
	# --------------------------------------------------------------------------

	# Update a user's auth provider (for linking accounts).
	def updateAuthProvider userId\number, provider\string, providerId\string
		self.table
			.where('id', userId)
			.update({
				auth_provider: provider
				auth_provider_id: providerId
			})

	# Mark a user's email as verified.
	def markEmailVerified userId\number
		self.table
			.where('id', userId)
			.update({
				email_verified_at: new Date!
			})

	# --------------------------------------------------------------------------
	# Utility Methods
	# --------------------------------------------------------------------------

	# Check if an email exists for any auth provider.
	def emailExists email\string
		const result = await self.table.where('email', email).first!
		!!result

	# Check if an email exists for a specific auth provider.
	def emailExistsForProvider email\string, provider\string
		const result = await self.table
			.where('email', email)
			.where('auth_provider', provider)
			.first!
		!!result

	# Get all users for a specific auth provider.
	def getByProvider provider\string
		self.table.where('auth_provider', provider)
