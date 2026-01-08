import { describe, it, expect } from 'vitest'
import { Kernel } from '../../app/Http/Kernel'

describe 'Kernel', do
	it 'registers InitPassport middleware', do
		const kernel = new Kernel
		const middleware = kernel.middleware
		
		# Find InitPassport by checking class names or structure
		# Since InitPassport is imported as a class, we check if it's in the list
		const initPassport = middleware.find(do(m) m.name === 'InitPassport')
		expect(initPassport).toBeDefined!

	it 'registers PassportAuth alias', do
		const kernel = new Kernel
		const aliases = kernel.middlewareAliases
		
		expect(aliases.passport).toBeDefined!
		expect(aliases.passport.name).toBe('PassportAuth')
