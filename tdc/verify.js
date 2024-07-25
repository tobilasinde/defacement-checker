import fs from 'fs'
import crypto from 'crypto'

const TDC_DIR = '/usr/lib/tdc'
const generateHash = (text) => {
	const hash = crypto.createHash('sha256')
	hash.update(text)
	return hash.digest('hex')
}
const getInitialHash = (filename, root) => {
	root = root.replace(/\//g, '_')
	const file_path = `${TDC_DIR}/hashes/${root}.json`
	if (fs.existsSync(file_path)) {
		var file = fs.readFileSync(file_path)
		file = file.toString()
		file = JSON.parse(file)
		if (file[filename]) return file[filename]
	}
	return null
}
let res = ''
let initalHash = null
function verify(r, data, flag) {
	res += data
	if (!initalHash)
		initalHash = getInitialHash(r.variables.request_filename, r.variables.document_root)
	if (!initalHash) r.done()
	if (flag.last) {
		if (r.variables.request_filename)
			res = fs.readFileSync(r.variables.request_filename)
		const hash = generateHash(res)
		if (initalHash && hash !== initalHash) {
			console.error(`${r.variables.request_filename} has been modified`)
			r.status = 404
			res = null
			// r.return(403)
			// return
		}
	}
	r.sendBuffer(data || res, flag)
}
function header(r) {
	delete r.headersOut['Content-Length']
}
export default {
	verify,
	header,
}