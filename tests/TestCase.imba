import { vi, beforeAll, afterAll, beforeEach, afterEach } from 'vitest'
import supertest from 'supertest'

# --------------------------------------------------------------------------
# TestCase Helper
# --------------------------------------------------------------------------
# Base test utilities for Formidable + Imba applications.
# Provides helpers for bootstrapping the app, making requests, and mocking auth.
#
# Usage:
#   import { TestCase } from '../TestCase'
#
#   describe 'My Feature', do
#       const tc = new TestCase
#
#       beforeAll do await tc.setup!
#       afterAll do await tc.teardown!
#       beforeEach do tc.reset!
#
#       it 'requires authentication', do
#           const res = await tc.get('/protected')
#           expect(res.status).toBe(401)
#
#       it 'allows authenticated users', do
#           tc.actingAs({ id: 1, email: 'test@example.com', name: 'Test User' })
#           const res = await tc.get('/protected')
#           expect(res.status).toBe(200)

export class TestCase

	# The Formidable application instance
	app = null

	# The Fastify server instance
	server = null

	# The currently authenticated user (for mocking)
	authenticatedUser = null

	# --------------------------------------------------------------------------
	# Lifecycle Methods
	# --------------------------------------------------------------------------

	# Set up the test environment. Call this in beforeAll.
	def setup
		try
			# Import the built Formidable application using require (same as existing Jest tests)
			const formidable = require('../.formidable/build').default
			const application = await formidable

			self.app = application.fastify!
			await self.app.ready!
			self.server = self.app.server
		catch err
			console.error '[TestCase] Failed to setup application:', err
			throw err

		self

	# Tear down the test environment. Call this in afterAll.
	def teardown
		if self.app
			await self.app.close!
		self.app = null
		self.server = null
		self.authenticatedUser = null
		self

	# Reset state between tests. Call this in beforeEach.
	def reset
		self.authenticatedUser = null
		self

	# --------------------------------------------------------------------------
	# Authentication Mocking
	# --------------------------------------------------------------------------

	# Mock authentication as a specific user.
	#
	# @param user - The user object to authenticate as. Should include at minimum:
	#   - id: number
	#   - email: string
	#   - name: string (optional)
	#   - auth_provider: 'local' | 'oidc' | 'ldap' (optional, defaults to 'local')
	#
	# @example
	#   tc.actingAs({ id: 1, email: 'admin@example.com', name: 'Admin' })
	#   const res = await tc.get('/dashboard')
	#
	# @example Creating a user with specific provider
	#   tc.actingAs({
	#       id: 2,
	#       email: 'oidc@example.com',
	#       name: 'OIDC User',
	#       auth_provider: 'oidc',
	#       auth_provider_id: 'oidc-sub-12345'
	#   })
	def actingAs user
		self.authenticatedUser = {
			id: user.id
			email: user.email
			name: user.name or 'Test User'
			auth_provider: user.auth_provider or 'local'
			auth_provider_id: user.auth_provider_id or null
			email_verified_at: user.email_verified_at or null
			created_at: user.created_at or new Date!
			updated_at: user.updated_at or new Date!
			...user
		}
		self

	# Clear the authenticated user.
	def actingAsGuest
		self.authenticatedUser = null
		self

	# --------------------------------------------------------------------------
	# HTTP Request Helpers
	# --------------------------------------------------------------------------

	# Create a supertest request with optional auth mocking.
	# This hooks into the request to inject authentication state.
	def request
		const req = supertest(self.server)

		# If we have an authenticated user, we need to mock the session
		# We'll add a custom hook on each request method
		req

	# Make a GET request.
	def get path, options = {}
		self.makeRequest('get', path, options)

	# Make a POST request.
	def post path, body = {}, options = {}
		self.makeRequest('post', path, { ...options, body })

	# Make a PUT request.
	def put path, body = {}, options = {}
		self.makeRequest('put', path, { ...options, body })

	# Make a PATCH request.
	def patch path, body = {}, options = {}
		self.makeRequest('patch', path, { ...options, body })

	# Make a DELETE request.
	def delete path, options = {}
		self.makeRequest('delete', path, options)

	# Internal: Make an HTTP request with auth mocking support.
	def makeRequest method, path, options = {}
		let req = supertest(self.server)[method](path)

		# Set default headers
		req = req.set('Accept', 'application/json')

		# Apply custom headers
		if options.headers
			for own key, value of options.headers
				req = req.set(key, value)

		# Apply body for POST/PUT/PATCH
		if options.body and method !== 'get' and method !== 'delete'
			req = req.send(options.body)

		# If authenticated, we need to mock the passport session
		# Since we can't easily inject session state, we'll use a different approach:
		# Hook into the request to add auth mocking headers that our test middleware can interpret
		if self.authenticatedUser
			req = req.set('X-Test-Auth-User', JSON.stringify(self.authenticatedUser))

		req

	# --------------------------------------------------------------------------
	# Assertion Helpers
	# --------------------------------------------------------------------------

	# Assert that a response has a specific status code.
	def assertStatus response, status
		expect(response.status).toBe(status)
		self

	# Assert that a response is successful (2xx).
	def assertOk response
		expect(response.status).toBeGreaterThanOrEqual(200)
		expect(response.status).toBeLessThan(300)
		self

	# Assert that a response is a redirect.
	def assertRedirect response, location = null
		expect(response.status).toBeGreaterThanOrEqual(300)
		expect(response.status).toBeLessThan(400)
		if location
			expect(response.headers.location).toBe(location)
		self

	# Assert that a response is unauthorized.
	def assertUnauthorized response
		expect(response.status).toBe(401)
		self

	# Assert that a response is forbidden.
	def assertForbidden response
		expect(response.status).toBe(403)
		self

	# Assert that a response is not found.
	def assertNotFound response
		expect(response.status).toBe(404)
		self

	# Assert that a JSON response contains specific data.
	def assertJson response, expected
		expect(response.body).toMatchObject(expected)
		self

	# Assert that a JSON response has a specific structure.
	def assertJsonStructure response, keys
		for key in keys
			expect(response.body).toHaveProperty(key)
		self

# --------------------------------------------------------------------------
# Factory Helper for creating test users
# --------------------------------------------------------------------------

export class UserFactory

	static counter = 0

	# Create a mock local user.
	static def createLocal overrides = {}
		UserFactory.counter += 1
		{
			id: overrides.id or UserFactory.counter
			email: overrides.email or "testuser{UserFactory.counter}@example.com"
			name: overrides.name or "Test User {UserFactory.counter}"
			auth_provider: 'local'
			auth_provider_id: null
			email_verified_at: overrides.email_verified_at or new Date!
			created_at: new Date!
			updated_at: new Date!
			...overrides
		}

	# Create a mock OIDC user.
	static def createOidc overrides = {}
		UserFactory.counter += 1
		{
			id: overrides.id or UserFactory.counter
			email: overrides.email or "oidcuser{UserFactory.counter}@example.com"
			name: overrides.name or "OIDC User {UserFactory.counter}"
			auth_provider: 'oidc'
			auth_provider_id: overrides.auth_provider_id or "oidc-sub-{UserFactory.counter}"
			email_verified_at: overrides.email_verified_at or new Date!
			created_at: new Date!
			updated_at: new Date!
			...overrides
		}

	# Create a mock LDAP user.
	static def createLdap overrides = {}
		UserFactory.counter += 1
		{
			id: overrides.id or UserFactory.counter
			email: overrides.email or "ldapuser{UserFactory.counter}@example.com"
			name: overrides.name or "LDAP User {UserFactory.counter}"
			auth_provider: 'ldap'
			auth_provider_id: overrides.auth_provider_id or "cn=user{UserFactory.counter},ou=users,dc=example,dc=com"
			email_verified_at: overrides.email_verified_at or new Date!
			created_at: new Date!
			updated_at: new Date!
			...overrides
		}

	# Reset the counter (call in beforeEach if needed)
	static def reset
		UserFactory.counter = 0
