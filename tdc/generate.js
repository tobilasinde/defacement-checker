const crypto = require('crypto')
const fs = require('fs')

const generateHash = (text) => {
	const hash = crypto.createHash('sha256')
	hash.update(text)
	return hash.digest('hex')
}
let hash = {}
function generateHashForDirectory(r) {
	const stats = fs.statSync(r)
	if (stats?.isFile()) {
		const file = fs.readFileSync(`${r}`)
		hash[r] = generateHash(file)
	} else if (stats?.isDirectory()) {
		const directory = fs.readdirSync(r)
		for (let i = 0; i < directory.length; i++)
			generateHashForDirectory(`${r}/${directory[i]}`)
	}
}
let dir = process.argv[2]
if (dir.endsWith('/')) dir = dir.slice(0, -1)
generateHashForDirectory(dir)
let filename = dir.replace(/\//g, '_')
fs.writeFileSync(
	`${process.argv[3]}/hashes/${filename}.json`,
	JSON.stringify(hash, null, 2)
)
console.log(`Hashes for ${process.argv[2]} generated successfully`)
