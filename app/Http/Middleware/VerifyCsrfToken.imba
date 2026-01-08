import { VerifyCsrfToken as Middleware } from '@formidablejs/framework'

export class VerifyCsrfToken < Middleware

	get except
		[
			'/auth/login'
			'/auth/ldap'
			'/auth/logout'
			'/auth/oidc/callback'
		]
