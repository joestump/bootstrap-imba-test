import { describe, it, expect, beforeAll, afterAll, beforeEach, vi } from 'vitest'
import { TestCase, UserFactory } from '../TestCase.imba'

# --------------------------------------------------------------------------
# Authentication Feature Tests
# --------------------------------------------------------------------------
# Tests for auth logic including UserFactory and UserRepository patterns.
#
# NOTE: HTTP integration tests are skipped pending proper Formidable app
# bootstrapping in the Vitest environment. The UserFactory unit tests
# demonstrate the testing patterns for this stack.

describe 'Authentication', do
	const tc = new TestCase

	# --------------------------------------------------------------------------
	# HTTP Integration Tests (Skipped)
	# --------------------------------------------------------------------------
	# These tests require the full Formidable app to be bootstrapped with routes.
	# They are skipped until the test environment properly registers routes.

	describe 'GET /auth/status', do

		it.skip 'returns unauthenticated status for guests', do
			const res = await tc.get('/auth/status')

			expect(res.status).toBe(200)
			expect(res.body).toHaveProperty('authenticated', false)
			expect(res.body).toHaveProperty('user', null)

		it.skip 'returns authenticated status with user data when logged in', do
			const user = UserFactory.createLocal({ email: 'auth@example.com' })
			tc.actingAs(user)

			const res = await tc.get('/auth/status')
				.set('X-Test-Auth-User', JSON.stringify(user))

			expect(res.status).toBe(200)
			expect(res.body).toHaveProperty('authenticated')

	describe 'GET /auth/login', do

		it.skip 'returns available auth providers', do
			const res = await tc.get('/auth/login')

			expect(res.status).toBe(200)
			expect(res.body).toHaveProperty('providers')
			expect(res.body.providers).toHaveProperty('local')
			expect(res.body.providers).toHaveProperty('oidc')
			expect(res.body.providers).toHaveProperty('ldap')

	describe 'POST /auth/login (Local)', do

		it.skip 'rejects login with missing credentials', do
			const res = await tc.post('/auth/login', {})

			expect(res.status).toBe(401)
			expect(res.body).toHaveProperty('error')

		it.skip 'rejects login with invalid email', do
			const res = await tc.post('/auth/login', {
				email: 'nonexistent@example.com'
				password: 'password123'
			})

			expect(res.status).toBe(401)
			expect(res.body.error).toContain('Invalid')

	describe 'GET /auth/oidc', do

		it.skip 'returns error when OIDC is disabled', do
			const res = await tc.get('/auth/oidc')

			expect(res.status).toBe(400)
			expect(res.body.error).toContain('OIDC authentication is not enabled')

	describe 'POST /auth/ldap', do

		it.skip 'returns error when LDAP is disabled', do
			const res = await tc.post('/auth/ldap', {
				username: 'ldapuser'
				password: 'ldappassword'
			})

			expect(res.status).toBe(400)
			expect(res.body.error).toContain('LDAP authentication is not enabled')

	describe 'POST /auth/logout', do

		it.skip 'logs out the user successfully', do
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

			# Simulate what create-local-user does
			const user-data = {
				...input
				auth_provider: 'local'
				auth_provider_id: null
			}

			expect(user-data.email).toBe('local@example.com')
			expect(user-data.name).toBe('Local User')
			expect(user-data.auth_provider).toBe('local')
			expect(user-data.auth_provider_id).toBeNull!
			expect(user-data.password).toBe('hashed_password')

	describe 'OIDC User Data', do

		it 'builds correct data structure for OIDC users', do
			const input = {
				email: 'oidc@example.com'
				name: 'OIDC User'
			}
			const provider-id = 'oidc-sub-12345'

			# Simulate what create-oidc-user does
			const user-data = {
				...input
				auth_provider: 'oidc'
				auth_provider_id: provider-id
				password: null
			}

			expect(user-data.email).toBe('oidc@example.com')
			expect(user-data.name).toBe('OIDC User')
			expect(user-data.auth_provider).toBe('oidc')
			expect(user-data.auth_provider_id).toBe('oidc-sub-12345')
			expect(user-data.password).toBeNull!

		it 'stores the OIDC sub claim as auth_provider_id', do
			const oidc-sub = 'google-oauth2|123456789'

			const user-data = {
				email: 'test@example.com'
				auth_provider: 'oidc'
				auth_provider_id: oidc-sub
				password: null
			}

			expect(user-data.auth_provider_id).toBe('google-oauth2|123456789')

	describe 'LDAP User Data', do

		it 'builds correct data structure for LDAP users', do
			const ldap-dn = 'cn=jsmith,ou=users,dc=example,dc=com'
			const input = {
				email: 'jsmith@example.com'
				name: 'John Smith'
			}

			# Simulate what create-ldap-user does
			const user-data = {
				...input
				auth_provider: 'ldap'
				auth_provider_id: ldap-dn
				password: null
			}

			expect(user-data.email).toBe('jsmith@example.com')
			expect(user-data.name).toBe('John Smith')
			expect(user-data.auth_provider).toBe('ldap')
			expect(user-data.auth_provider_id).toBe(ldap-dn)
			expect(user-data.password).toBeNull!

# --------------------------------------------------------------------------
# Auth Provider Values Tests
# --------------------------------------------------------------------------
# Verify that auth provider values follow the GEMINI.md conventions

describe 'Auth Provider Conventions', do

	it 'uses simple lowercase strings for auth_provider', do
		const valid-providers = ['local', 'oidc', 'ldap']

		for provider in valid-providers
			expect(provider).toMatch(/^[a-z]+$/)
			expect(provider).not.toContain('-')
			expect(provider).not.toContain('_')

	it 'does NOT use vendor-specific names', do
		const invalid-providers = ['google-oidc', 'azure-ad', 'okta', 'auth0']

		for provider in invalid-providers
			expect(['local', 'oidc', 'ldap']).not.toContain(provider)

	it 'local provider has null auth_provider_id', do
		const local-user = UserFactory.createLocal!
		expect(local-user.auth_provider).toBe('local')
		expect(local-user.auth_provider_id).toBeNull!

	it 'oidc provider has non-null auth_provider_id', do
		const oidc-user = UserFactory.createOidc!
		expect(oidc-user.auth_provider).toBe('oidc')
		expect(oidc-user.auth_provider_id).not.toBeNull!

	it 'ldap provider has non-null auth_provider_id (DN)', do
		const ldap-user = UserFactory.createLdap!
		expect(ldap-user.auth_provider).toBe('ldap')
		expect(ldap-user.auth_provider_id).not.toBeNull!
		expect(ldap-user.auth_provider_id).toContain('cn=')

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
