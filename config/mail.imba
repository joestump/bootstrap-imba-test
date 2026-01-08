export default {
	# --------------------------------------------------------------------------
	# Default Mailer
	# --------------------------------------------------------------------------
	#
	# This option controls the default mailer that will be used for sending.

	default: 'smtp'


	# --------------------------------------------------------------------------
	# Mailer Error Handling
	# --------------------------------------------------------------------------
	#
	# This option controls whether or not Formidable will ignore errors when
	# sending email. Typically you should set this value to false so that any
	# errors will be shown in the console.

	ignore_errors: false

	# --------------------------------------------------------------------------
	# Mailer Configuration
	# --------------------------------------------------------------------------
	#
	# Here you may configure all of the mailers used by Formidable.
	#
	# Supported: "smtp", "sendmail"

	mailers: {
		smtp: {
			transport: 'smtp'
			host: env 'MAIL_HOST', 'smtp.mailgun.org'
			port: env 'MAIL_PORT', 587
			secure: env 'MAIL_SECURE', true
			username: env 'MAIL_USERNAME'
			password: env 'MAIL_PASSWORD'
		}

		sendmail: {
			transport: 'sendmail'
			newline: 'unix'
			path: '/usr/sbin/sendmail'
		}
	}

	# --------------------------------------------------------------------------
	# Global "From" Address
	# --------------------------------------------------------------------------
	#
	# The email address that will be used in the "From" field of all emails.

	from: {
		address: env 'MAIL_FROM_ADDRESS', 'hello@example.com'
		name: env 'MAIL_FROM_NAME', 'Example'
	}
}
