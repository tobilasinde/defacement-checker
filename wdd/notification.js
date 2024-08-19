const { createTransport } = require('nodemailer')
const env = {
	MAIL_HOST: 'mail.starlightesolutions.com',
	MAIL_PASSWORD: '',
	MAIL_PORT: 587,
	MAIL_USERNAME: 'alert@starlightesolutions.com',
	MAIL_FROM_NAME: '"WDD ALERT" <alert@starlightesolutions.com>'
}
const email = 'tobilasinde2012@yahoo.com'
async function sendEmail(data) {
	try {
		data.to = email
		if (!data.from) data.from = env.MAIL_FROM_NAME
		// Set Mail Authentications
		let transporter = createTransport({
			host: env.MAIL_HOST,
			port: Number(env.MAIL_PORT),
			//secure: true,
			auth: {
				user: env.MAIL_USERNAME,
				pass: env.MAIL_PASSWORD,
			},
		})
		// Send Emails
		transporter.sendMail(data, function (error, info) {
			if (error) {
				return {
					status: false,
					message: error,
					email: data.to,
				}
			} else {
				return {
					status: true,
					message: 'Email sent successfully',
					email: data.to,
				}
			}
		})
	} catch (error) {
		return error
	}
}
module.exports = { sendEmail }