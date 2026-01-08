import { useForm } from '@formidablejs/view'
import { useProp } from '@formidablejs/view'
import { FormProgress } from '@formidablejs/view'
import { Welcome } from './pages/Welcome'
import { Login } from './pages/Auth/Login'
import { LoginPage } from './pages/Auth/LoginPage'
import { Register } from './pages/Auth/Register'
import { EmailVerification } from './pages/Auth/EmailVerification'
import { EmailUnverified } from './pages/Auth/EmailUnverified'
import { ForgotPassword } from './pages/Auth/ForgotPassword'
import { PasswordReset } from './pages/Auth/PasswordReset'
import { Dashboard } from './pages/Dashboard'
import '../css/app.css'

export tag App
	prop user\User = useProp('user')

	def mount
		if user && !user.email_verified_at && router.pathname !== '/email/verify'
			router.go('/email/unverified')

	def render
		<self>
			<FormProgress observeUrl>

			<Welcome route="/">

			<Login route="/login">
			<LoginPage route="/login-page">
			<Register route="/register">

			<Dashboard route="/dashboard">

			<EmailUnverified route="/email/unverified">
			<EmailVerification route="/email/verify">

			<ForgotPassword route="/forgot-password">
			<PasswordReset route="/password/reset">
