import crypto from 'crypto'
import fs from 'fs'

const generateHash = (text) => {
	const hash = crypto.createHash('sha256')
	hash.update(text)
	return hash.digest('base64url')
}
let res = ''
let initalHash = null
function verify(r, data, flag) {
	res += data
	if (
		!initalHash &&
		r.variables['app_name'] &&
		fs.existsSync(`./njs/hashes/${r.variables['app_name']}.json`)
	) {
		var file = fs.readFileSync(`./njs/hashes/${r.variables['app_name']}.json`)
		file = file.toString()
		file = JSON.parse(file)
		if (file[r.uri]) initalHash = file[r.uri]
	}
	if (!initalHash) r.done()
	if (flag.last) {
		if (res.length == 0 && r.variables.request_filename)
			res = fs.readFileSync(r.variables.request_filename)
		const hash = generateHash(res)
		if (initalHash && hash !== initalHash) {
			r.status = 404
			res = null
		}
	}
	r.sendBuffer(res, flag)
}
function header(r) {
	delete r.headersOut['Content-Length']
}
export default {
	verify,
	header,
}
