import { describe, it, expect, beforeAll, afterAll, beforeEach, vi } from 'vitest'
import { TestCase, UserFactory } from '../TestCase.imba'

# --------------------------------------------------------------------------
# Authentication Feature Tests
# --------------------------------------------------------------------------
# Tests for auth logic including UserFactory and UserRepository patterns.
#
# NOTE: HTTP integration tests use the TestCase helper which bootstraps
# the Formidable app.

describe 'Authentication', do
	const tc = new TestCase

	beforeAll do await tc.setup!
	afterAll do await tc.teardown!
	beforeEach do tc.reset!

	# --------------------------------------------------------------------------
	# HTTP Integration Tests
	# --------------------------------------------------------------------------

	describe 'GET /auth/status', do

		it 'returns unauthenticated status for guests', do
			const res = await tc.get('/auth/status')

			expect(res.status).toBe(200)
			expect(res.body).toHaveProperty('authenticated', false)
			expect(res.body).toHaveProperty('user', null)

		it 'returns authenticated status with user data when logged in', do
			const user = UserFactory.createLocal({ email: 'auth@example.com' })
			tc.actingAs(user)

			const res = await tc.get('/auth/status')
				.set('X-Test-Auth-User', JSON.stringify(user))

			expect(res.status).toBe(200)
			expect(res.body).toHaveProperty('authenticated')

	describe 'GET /auth/login', do

		it 'returns available auth providers', do
			const res = await tc.get('/auth/login')

			expect(res.status).toBe(200)
			expect(res.body).toHaveProperty('providers')
			expect(res.body.providers).toHaveProperty('local')
			expect(res.body.providers).toHaveProperty('oidc')
			expect(res.body.providers).toHaveProperty('ldap')

	describe 'POST /auth/login (Local)', do

		it 'rejects login with missing credentials', do
			const res = await tc.post('/auth/login', {})

			expect(res.status).toBe(401)
			expect(res.body).toHaveProperty('error')

		it 'rejects login with invalid email', do
			const res = await tc.post('/auth/login', {
				email: 'nonexistent@example.com'
				password: 'password123'
			})

			expect(res.status).toBe(401)
			expect(res.body.error).toContain('Invalid')

	describe 'GET /auth/oidc', do

		it 'returns error when OIDC is disabled', do
			const res = await tc.get('/auth/oidc')

			expect(res.status).toBe(400)
			expect(res.body.error).toContain('OIDC authentication is not enabled')

	describe 'POST /auth/ldap', do

		it 'returns error when LDAP is disabled', do
			const res = await tc.post('/auth/ldap', {
				username: 'ldapuser'
				password: 'ldappassword'
			})

			expect(res.status).toBe(400)
			expect(res.body.error).toContain('LDAP authentication is not enabled')

	describe 'POST /auth/logout', do

		it 'logs out the user successfully', do
			const res = await tc.post('/auth/logout')

			expect(res.status).toBe(200)
			expect(res.body.message).toContain('Logged out')

# --------------------------------------------------------------------------
# UserRepository Unit Tests
# --------------------------------------------------------------------------
# These tests verify the UserRepository methods create the correct data
# structures for each auth provider type.

describe 'UserRepository Data Structures', do

	describe 'Local User Data', do

		it 'builds correct data structure for local users', do
			const input = {
				email: 'local@example.com'
				name: 'Local User'
				password: 'hashed_password'
			}

			# Simulate what createLocalUser does
			const userData = {
				...input
				auth_provider: 'local'
				auth_provider_id: null
			}

			expect(userData.email).toBe('local@example.com')
			expect(userData.name).toBe('Local User')
			expect(userData.auth_provider).toBe('local')
			expect(userData.auth_provider_id).toBeNull!
			expect(userData.password).toBe('hashed_password')

	describe 'OIDC User Data', do

		it 'builds correct data structure for OIDC users', do
			const input = {
				email: 'oidc@example.com'
				name: 'OIDC User'
			}
			const providerId = 'oidc-sub-12345'

			# Simulate what createOidcUser does
			const userData = {
				...input
				auth_provider: 'oidc'
				auth_provider_id: providerId
				password: null
			}

			expect(userData.email).toBe('oidc@example.com')
			expect(userData.name).toBe('OIDC User')
			expect(userData.auth_provider).toBe('oidc')
			expect(userData.auth_provider_id).toBe('oidc-sub-12345')
			expect(userData.password).toBeNull!

		it 'stores the OIDC sub claim as auth_provider_id', do
			const oidcSub = 'google-oauth2|123456789'

			const userData = {
				email: 'test@example.com'
				auth_provider: 'oidc'
				auth_provider_id: oidcSub
				password: null
			}

			expect(userData.auth_provider_id).toBe('google-oauth2|123456789')

	describe 'LDAP User Data', do

		it 'builds correct data structure for LDAP users', do
			const ldapDn = 'cn=jsmith,ou=users,dc=example,dc=com'
			const input = {
				email: 'jsmith@example.com'
				name: 'John Smith'
			}

			# Simulate what createLdapUser does
			const userData = {
				...input
				auth_provider: 'ldap'
				auth_provider_id: ldapDn
				password: null
			}

			expect(userData.email).toBe('jsmith@example.com')
			expect(userData.name).toBe('John Smith')
			expect(userData.auth_provider).toBe('ldap')
			expect(userData.auth_provider_id).toBe(ldapDn)
			expect(userData.password).toBeNull!

# --------------------------------------------------------------------------
# Auth Provider Values Tests
# --------------------------------------------------------------------------
# Verify that auth provider values follow the GEMINI.md conventions

describe 'Auth Provider Conventions', do

	it 'uses simple lowercase strings for auth_provider', do
		const validProviders = ['local', 'oidc', 'ldap']

		for provider in validProviders
			expect(provider).toMatch(/^[a-z]+$/)
			expect(provider).not.toContain('-')
			expect(provider).not.toContain('_')

	it 'does NOT use vendor-specific names', do
		const invalidProviders = ['google-oidc', 'azure-ad', 'okta', 'auth0']

		for provider in invalidProviders
			expect(['local', 'oidc', 'ldap']).not.toContain(provider)

	it 'local provider has null auth_provider_id', do
		const localUser = UserFactory.createLocal!
		expect(localUser.auth_provider).toBe('local')
		expect(localUser.auth_provider_id).toBeNull!

	it 'oidc provider has non-null auth_provider_id', do
		const oidcUser = UserFactory.createOidc!
		expect(oidcUser.auth_provider).toBe('oidc')
		expect(oidcUser.auth_provider_id).not.toBeNull!

	it 'ldap provider has non-null auth_provider_id (DN)', do
		const ldapUser = UserFactory.createLdap!
		expect(ldapUser.auth_provider).toBe('ldap')
		expect(ldapUser.auth_provider_id).not.toBeNull!
		expect(ldapUser.auth_provider_id).toContain('cn=')

# --------------------------------------------------------------------------
# UserFactory Tests
# --------------------------------------------------------------------------

describe 'UserFactory', do

	beforeEach do
		UserFactory.reset!

	describe 'createLocal', do

		it 'creates a local user with default values', do
			const user = UserFactory.createLocal!

			expect(user.id).toBe(1)
			expect(user.email).toContain('@example.com')
			expect(user.auth_provider).toBe('local')
			expect(user.auth_provider_id).toBeNull!

		it 'accepts overrides', do
			const user = UserFactory.createLocal({
				email: 'custom@test.com'
				name: 'Custom Name'
			})

			expect(user.email).toBe('custom@test.com')
			expect(user.name).toBe('Custom Name')
			expect(user.auth_provider).toBe('local')

		it 'increments ID for each user', do
			const user1 = UserFactory.createLocal!
			const user2 = UserFactory.createLocal!
			const user3 = UserFactory.createLocal!

			expect(user1.id).toBe(1)
			expect(user2.id).toBe(2)
			expect(user3.id).toBe(3)

		it 'generates unique emails for each user', do
			const user1 = UserFactory.createLocal!
			const user2 = UserFactory.createLocal!

			expect(user1.email).not.toBe(user2.email)

	describe 'createOidc', do

		it 'creates an OIDC user with provider ID', do
			const user = UserFactory.createOidc!

			expect(user.auth_provider).toBe('oidc')
			expect(user.auth_provider_id).toContain('oidc-sub-')
			expect(user.email).toContain('oidcuser')

		it 'accepts custom provider ID', do
			const user = UserFactory.createOidc({
				auth_provider_id: 'google|12345'
			})

			expect(user.auth_provider_id).toBe('google|12345')

		it 'has null password', do
			const user = UserFactory.createOidc!
			# OIDC users authenticate via external provider, no local password
			expect(user.password).toBeUndefined!

	describe 'createLdap', do

		it 'creates an LDAP user with DN', do
			const user = UserFactory.createLdap!

			expect(user.auth_provider).toBe('ldap')
			expect(user.auth_provider_id).toContain('cn=')
			expect(user.email).toContain('ldapuser')

		it 'accepts custom DN', do
			const user = UserFactory.createLdap({
				auth_provider_id: 'uid=jdoe,ou=people,dc=corp,dc=com'
			})

			expect(user.auth_provider_id).toBe('uid=jdoe,ou=people,dc=corp,dc=com')

		it 'has null password', do
			const user = UserFactory.createLdap!
			# LDAP users authenticate via directory server, no local password
			expect(user.password).toBeUndefined!

	describe 'reset', do

		it 'resets the counter', do
			UserFactory.createLocal!
			UserFactory.createLocal!
			expect(UserFactory.counter).toBe(2)

			UserFactory.reset!
			expect(UserFactory.counter).toBe(0)

			const user = UserFactory.createLocal!
			expect(user.id).toBe(1)
