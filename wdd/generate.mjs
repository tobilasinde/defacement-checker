import fs from 'fs'
import { sendEmail } from './notification.js'
import generateHash from './generateHash.mjs'

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
let str = JSON.stringify(hash, null, 2)
fs.writeFileSync(
	`${process.argv[3]}/hashes/${filename}.json`,
	str
)
const website_name = filename.split('_').pop()
const checksum = generateHash(str)
sendEmail({
	subject: website_name + ' initialised successfully',
	html: `<div>Dear Admin,</div><div>${website_name} has been successfully initiated and ready for future verification.</div> <div>The checksum for the file is <b>${checksum}</b>.</div> <div>Be sure to keep this safe as you will use the checksum to perform manual verification in future</div><div>Best regards</div><div>WDD Team</div>`
})
console.log(`Hashes for ${process.argv[2]} generated successfully`)
