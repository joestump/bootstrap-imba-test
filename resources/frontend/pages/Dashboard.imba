import { useProp } from '@formidablejs/view'
import { useForm } from '@formidablejs/view'

export tag Dashboard
	prop user\User = useProp('user')

	def routed
		# Redirect to login if not authenticated
		unless user
			globalThis.location.assign('/login-page')

	def handle-logout
		# Use fetch to call logout endpoint, then redirect
		window.fetch('/auth/logout', { method: 'POST' }).then do
			globalThis.location.assign('/login-page')

	css
		display: block
		min-height: 100vh
		background: #f3f4f6

		.dashboard-header
			background: linear-gradient(135deg, #667eea 0%, #764ba2 100%)
			color: white
			padding: 1.5rem 2rem
			display: flex
			justify-content: space-between
			align-items: center
			box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1)

			.header-left
				display: flex
				align-items: center
				gap: 1rem

				h1
					font-size: 1.5rem
					font-weight: 700
					margin: 0

				.badge
					background: rgba(255, 255, 255, 0.2)
					padding: 0.25rem 0.75rem
					border-radius: 9999px
					font-size: 0.75rem
					font-weight: 500

			.header-right
				display: flex
				align-items: center
				gap: 1rem

				.user-info
					text-align: right

					.user-name
						font-weight: 600
						font-size: 0.95rem

					.user-email
						font-size: 0.8rem
						opacity: 0.8

				.avatar
					width: 40px
					height: 40px
					border-radius: 50%
					background: rgba(255, 255, 255, 0.3)
					display: flex
					align-items: center
					justify-content: center
					font-weight: 700
					font-size: 1rem

				.btn-logout
					background: rgba(255, 255, 255, 0.15)
					border: 1px solid rgba(255, 255, 255, 0.3)
					color: white
					padding: 0.5rem 1rem
					border-radius: 8px
					font-size: 0.875rem
					font-weight: 500
					cursor: pointer
					transition: all 0.2s ease

					&:hover
						background: rgba(255, 255, 255, 0.25)

		.dashboard-content
			padding: 2rem
			max-width: 1200px
			margin: 0 auto

		.welcome-section
			background: white
			border-radius: 12px
			padding: 2rem
			margin-bottom: 2rem
			box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1)

			h2
				font-size: 1.5rem
				color: #1f2937
				margin: 0 0 0.5rem 0

			p
				color: #6b7280
				margin: 0
				font-size: 1rem

		.stats-grid
			display: grid
			grid-template-columns: repeat(auto-fit, minmax(240px, 1fr))
			gap: 1.5rem
			margin-bottom: 2rem

		.stat-card
			background: white
			border-radius: 12px
			padding: 1.5rem
			box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1)
			transition: transform 0.2s ease, box-shadow 0.2s ease

			&:hover
				transform: translateY(-2px)
				box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1)

			.stat-icon
				width: 48px
				height: 48px
				border-radius: 10px
				display: flex
				align-items: center
				justify-content: center
				margin-bottom: 1rem
				font-size: 1.5rem

				&.purple
					background: rgba(102, 126, 234, 0.1)
					color: #667eea

				&.green
					background: rgba(16, 185, 129, 0.1)
					color: #10b981

				&.orange
					background: rgba(245, 158, 11, 0.1)
					color: #f59e0b

				&.blue
					background: rgba(59, 130, 246, 0.1)
					color: #3b82f6

			.stat-value
				font-size: 2rem
				font-weight: 700
				color: #1f2937
				margin-bottom: 0.25rem

			.stat-label
				color: #6b7280
				font-size: 0.875rem

		.info-section
			background: white
			border-radius: 12px
			padding: 2rem
			box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1)

			h3
				font-size: 1.25rem
				color: #1f2937
				margin: 0 0 1.5rem 0
				padding-bottom: 0.75rem
				border-bottom: 1px solid #e5e7eb

			.info-grid
				display: grid
				grid-template-columns: repeat(auto-fit, minmax(280px, 1fr))
				gap: 1rem

			.info-item
				display: flex
				align-items: flex-start
				gap: 0.75rem
				padding: 0.75rem
				border-radius: 8px
				transition: background 0.2s ease

				&:hover
					background: #f9fafb

				.info-icon
					width: 36px
					height: 36px
					border-radius: 8px
					background: #f3f4f6
					display: flex
					align-items: center
					justify-content: center
					flex-shrink: 0

				.info-content
					flex: 1

					.info-label
						font-size: 0.75rem
						color: #9ca3af
						text-transform: uppercase
						letter-spacing: 0.05em
						margin-bottom: 0.25rem

					.info-value
						color: #374151
						font-weight: 500

	def get-initials name
		return '?' unless name
		const parts = name.split(' ')
		if parts.length >= 2
			"{parts[0][0]}{parts[1][0]}".toUpperCase!
		else
			name[0].toUpperCase!

	def render
		<self>
			<header.dashboard-header>
				<div.header-left>
					<h1> "Dashboard"
					<span.badge> "Protected"

				<div.header-right>
					if user
						<div.user-info>
							<div.user-name> user.name or 'User'
							<div.user-email> user.email
						<div.avatar>
							get-initials(user.name)
						<button.btn-logout @click=handle-logout>
							"Sign Out"

			<main.dashboard-content>
				<section.welcome-section>
					<h2> "Welcome back, {user?.name or 'User'}!"
					<p> "Here's an overview of your account and activity."

				<section.stats-grid>
					<div.stat-card>
						<div.stat-icon.purple> "📊"
						<div.stat-value> "12"
						<div.stat-label> "Total Projects"

					<div.stat-card>
						<div.stat-icon.green> "✓"
						<div.stat-value> "8"
						<div.stat-label> "Completed Tasks"

					<div.stat-card>
						<div.stat-icon.orange> "⏳"
						<div.stat-value> "4"
						<div.stat-label> "Pending Items"

					<div.stat-card>
						<div.stat-icon.blue> "👥"
						<div.stat-value> "3"
						<div.stat-label> "Team Members"

				<section.info-section>
					<h3> "Account Information"
					<div.info-grid>
						<div.info-item>
							<div.info-icon> "👤"
							<div.info-content>
								<div.info-label> "Full Name"
								<div.info-value> user?.name or 'Not provided'

						<div.info-item>
							<div.info-icon> "✉️"
							<div.info-content>
								<div.info-label> "Email Address"
								<div.info-value> user?.email or 'Not provided'

						<div.info-item>
							<div.info-icon> "🔐"
							<div.info-content>
								<div.info-label> "Auth Provider"
								<div.info-value> (user?.auth_provider or 'local').toUpperCase!

						<div.info-item>
							<div.info-icon> "📅"
							<div.info-content>
								<div.info-label> "Account Status"
								<div.info-value> "Active"
