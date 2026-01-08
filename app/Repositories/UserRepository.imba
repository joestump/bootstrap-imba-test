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
	def find-by-email email\string
		self.query!.where('email', email).first!

	# Find a user by their auth provider and provider ID.
	# Use this for OIDC/LDAP lookups where we match on external identity.
	def find-by-provider provider\string, provider-id\string
		self.query!
			.where('auth_provider', provider)
			.where('auth_provider_id', provider-id)
			.first!

	# Find a user by email and specific auth provider.
	# Useful when the same email might exist across different providers.
	def find-by-email-and-provider email\string, provider\string
		self.query!
			.where('email', email)
			.where('auth_provider', provider)
			.first!

	# --------------------------------------------------------------------------
	# Creation Methods
	# --------------------------------------------------------------------------

	# Create a new local user (username/password auth).
	def create-local-user data\object
		const user-data = {
			...data
			auth_provider: 'local'
			auth_provider_id: null
		}
		self.create(user-data)

	# Create a new OIDC user.
	# The provider-id should be the 'sub' claim from the OIDC token.
	def create-oidc-user data\object, provider-id\string
		const user-data = {
			...data
			auth_provider: 'oidc'
			auth_provider_id: provider-id
			password: null
		}
		self.create(user-data)

	# Create a new LDAP user.
	# The provider-id should be the DN or unique identifier from LDAP.
	def create-ldap-user data\object, provider-id\string
		const user-data = {
			...data
			auth_provider: 'ldap'
			auth_provider_id: provider-id
			password: null
		}
		self.create(user-data)

	# --------------------------------------------------------------------------
	# Update Methods
	# --------------------------------------------------------------------------

	# Update a user's auth provider (for linking accounts).
	def update-auth-provider user-id\number, provider\string, provider-id\string
		self.query!
			.where('id', user-id)
			.update({
				auth_provider: provider
				auth_provider_id: provider-id
			})

	# Mark a user's email as verified.
	def mark-email-verified user-id\number
		self.query!
			.where('id', user-id)
			.update({
				email_verified_at: new Date!
			})

	# --------------------------------------------------------------------------
	# Utility Methods
	# --------------------------------------------------------------------------

	# Check if an email exists for any auth provider.
	def email-exists email\string
		const result = await self.query!.where('email', email).first!
		!!result

	# Check if an email exists for a specific auth provider.
	def email-exists-for-provider email\string, provider\string
		const result = await self.query!
			.where('email', email)
			.where('auth_provider', provider)
			.first!
		!!result

	# Get all users for a specific auth provider.
	def get-by-provider provider\string
		self.query!.where('auth_provider', provider)
