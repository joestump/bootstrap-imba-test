import { useProp } from '@formidablejs/view'
import { useForm } from '@formidablejs/view'

export tag LoginPage
	prop user\User = useProp('user')

	prop form = useForm({
		email: ''
		password: ''
	})

	prop providers = {
		local: true
		oidc: false
		ldap: false
	}

	prop loading = false
	prop error = null

	def mount
		# Fetch available auth providers from login endpoint
		try
			const res = await window.fetch('/auth/login')
			const data = await res.json!
			if data.providers
				providers = data.providers
		catch e
			console.error 'Failed to fetch auth providers:', e

	def routed
		# Redirect if already logged in
		if user then router.go('/dashboard')

		# Check for error query params (from OIDC callback failures)
		const url = new URL(window.location.href)
		const err = url.searchParams.get('error')
		if err
			error = decodeURIComponent(err).replace(/_/g, ' ')

	def handle-local-login e
		e.preventDefault!
		error = null
		loading = true

		try
			await form.on('login')
			globalThis.location.assign('/dashboard')
		catch err
			error = err.message or 'Login failed. Please try again.'
		finally
			loading = no

	def handle-oidc-login
		# Redirect to OIDC provider
		globalThis.location.assign('/auth/oidc')

	def handle-ldap-login e
		e.preventDefault!
		error = null
		loading = true

		try
			const res = await window.fetch('/auth/ldap', {
				method: 'POST'
				headers: { 'Content-Type': 'application/json' }
				body: JSON.stringify({
					username: form.email
					password: form.password
				})
			})
			const data = await res.json!
			if res.ok
				globalThis.location.assign('/dashboard')
			else
				error = data.error or 'LDAP authentication failed.'
		catch err
			error = err.message or 'LDAP login failed. Please try again.'
		finally
			loading = no

	css
		display: flex
		justify-content: center
		align-items: center
		min-height: 100vh
		padding: 1rem
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%)

		.login-card
			background: white
			border-radius: 12px
			box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2)
			padding: 2.5rem
			width: 100%
			max-width: 400px

		.logo-section
			text-align: center
			margin-bottom: 2rem

			h1
				font-size: 1.75rem
				font-weight: 700
				color: #1a1a2e
				margin: 0 0 0.5rem 0

			p
				color: #6b7280
				margin: 0
				font-size: 0.95rem

		.error-banner
			background: #fef2f2
			border: 1px solid #fecaca
			border-radius: 8px
			padding: 0.75rem 1rem
			margin-bottom: 1.5rem
			color: #dc2626
			font-size: 0.875rem
			text-align: center

		.form-group
			margin-bottom: 1.25rem

			label
				display: block
				font-size: 0.875rem
				font-weight: 500
				color: #374151
				margin-bottom: 0.5rem

			input
				display: block
				width: 100%
				padding: 0.75rem 1rem
				font-size: 1rem
				border: 1px solid #d1d5db
				border-radius: 8px
				transition: all 0.2s ease
				box-sizing: border-box
				outline: none

				&:focus
					border-color: #667eea
					box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.15)

				&.has-error
					border-color: #ef4444

		.field-error
			color: #dc2626
			font-size: 0.8rem
			margin-top: 0.375rem

		.btn
			display: flex
			align-items: center
			justify-content: center
			width: 100%
			padding: 0.875rem 1.5rem
			font-size: 1rem
			font-weight: 600
			border-radius: 8px
			cursor: pointer
			transition: all 0.2s ease
			border: none
			box-sizing: border-box

			&:disabled
				opacity: 0.6
				cursor: not-allowed

		.btn-primary
			background: linear-gradient(135deg, #667eea 0%, #764ba2 100%)
			color: white

			&:hover:not(:disabled)
				transform: translateY(-1px)
				box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4)

			&:active:not(:disabled)
				transform: translateY(0)

		.btn-sso
			background: white
			color: #374151
			border: 1px solid #d1d5db
			gap: 0.5rem

			&:hover:not(:disabled)
				background: #f9fafb
				border-color: #9ca3af

		.btn-ldap
			background: #1e40af
			color: white
			gap: 0.5rem

			&:hover:not(:disabled)
				background: #1e3a8a

		.divider
			display: flex
			align-items: center
			margin: 1.5rem 0
			color: #9ca3af
			font-size: 0.875rem

			&::before, &::after
				content: ''
				flex: 1
				height: 1px
				background: #e5e7eb

			span
				padding: 0 1rem

		.footer-links
			margin-top: 1.5rem
			text-align: center
			font-size: 0.875rem
			color: #6b7280

			a
				color: #667eea
				text-decoration: none
				font-weight: 500

				&:hover
					text-decoration: underline

		.sso-section
			display: flex
			flex-direction: column
			gap: 0.75rem

		.spinner
			display: inline-block
			width: 1rem
			height: 1rem
			border: 2px solid rgba(255,255,255,0.3)
			border-top-color: white
			border-radius: 50%
			animation: spin 0.8s linear infinite
			margin-right: 0.5rem

		@keyframes spin
			to
				transform: rotate(360deg)

	def render
		<self>
			<div.login-card>
				<div.logo-section>
					<h1> "Welcome Back"
					<p> "Sign in to your account"

				if error
					<div.error-banner>
						error

				# Local Login Form
				if providers.local
					<form @submit=handle-local-login>
						<div.form-group>
							<label for="email"> "Email Address"
							<input#email
								type="email"
								placeholder="you@example.com"
								bind=form.email
								required
								.has-error=form.errors.email
							>
							if form.errors.email
								<div.field-error>
									err for err in form.errors.email

						<div.form-group>
							<label for="password"> "Password"
							<input#password
								type="password"
								placeholder="••••••••"
								bind=form.password
								required
								.has-error=form.errors.password
							>
							if form.errors.password
								<div.field-error>
									err for err in form.errors.password

						<button.btn.btn-primary type="submit" disabled=loading>
							if loading
								<span.spinner>
								"Signing in..."
							else
								"Sign In"

				# SSO Divider
				if providers.local and (providers.oidc or providers.ldap)
					<div.divider>
						<span> "or continue with"

				# SSO Buttons
				if providers.oidc or providers.ldap
					<div.sso-section>
						if providers.oidc
							<button.btn.btn-sso type="button" @click=handle-oidc-login disabled=loading>
								<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
									<circle cx="12" cy="12" r="10">
									<path d="M12 8v8">
									<path d="M8 12h8">
								"Sign in with SSO"

						if providers.ldap
							<button.btn.btn-ldap type="button" @click=handle-ldap-login disabled=loading>
								<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
									<rect x="3" y="3" width="18" height="18" rx="2">
									<path d="M9 12h6">
									<path d="M12 9v6">
								"Sign in with LDAP"

				# Footer Links
				<div.footer-links>
					<span> "Don't have an account? "
					<a route-to="/register"> "Sign up"
