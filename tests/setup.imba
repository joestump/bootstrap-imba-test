import { vi } from 'vitest'

# --------------------------------------------------------------------------
# Vitest Setup for Formidable + Imba
# --------------------------------------------------------------------------
# This file is loaded before all tests run.
# Use it to configure global test utilities, mocks, and environment setup.

# Mock process.send to prevent Formidable's internal IPC from conflicting with Vitest
const original-send = process.send
process.send = do(message, ...args)
	# Ignore Formidable's internal messages during tests
	if message && typeof message == 'object' && message.type == 'newListener'
		return true
	# Call original if it exists and message is not a Formidable internal
	if original-send
		original-send.call(process, message, ...args)
	true

# Set test environment variables
process.env.NODE_ENV = 'testing'
process.env.AUTH_LOCAL_ENABLED = 'true'
process.env.OIDC_ENABLED = 'false'
process.env.LDAP_ENABLED = 'false'

# Silence console output during tests unless DEBUG is set
unless process.env.DEBUG
	vi.spyOn(console, 'log').mockImplementation(do)
	vi.spyOn(console, 'info').mockImplementation(do)

# Global test utilities
global.vi = vi
