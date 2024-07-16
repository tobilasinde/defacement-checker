const crypto = require('crypto')
const fs = require('fs')

const generateHash = (text) => {
	const hash = crypto.createHash('sha256')
	hash.update(text)
	return hash.digest('base64url')
}
const dir = process.argv[3]
let hash = {}
function generateHashForDirectory(r) {
	const stats = fs.statSync(r)
	if (stats?.isFile()) {
		const file = fs.readFileSync(`${r}`)
		hash[r.split(dir)[1]] = generateHash(file)
	} else if (stats?.isDirectory()) {
		const directory = fs.readdirSync(r)
		for (let i = 0; i < directory.length; i++)
			generateHashForDirectory(`${r}/${directory[i]}`)
	}
}
generateHashForDirectory(dir)
fs.writeFileSync(
	`${process.argv[4]}/hashes/${process.argv[2]}.json`,
	JSON.stringify(hash, null, 2)
)
