
import fs from 'fs'
import generateHash from './generateHash.mjs'
import verificationService from './verificationService.mjs'
import { sendEmail } from './notification.js'

let fileCheck = {}
const errors = {}
let error
const verify = () => {
    if (process.argv[3].endsWith('/')) process.argv[3] = process.argv[3].slice(0, -1)
    let hash_file = process.argv[3].replace(/\//g, '_')
    const file_path = `${process.argv[2]}/hashes/${hash_file}.json`
    if (fs.existsSync(file_path)) {
        const file = fs.readFileSync(file_path)
        const hash = generateHash(file)
        if (process.argv[4] && hash !== process.argv[4]) {
            error = 'BAD CHECKSUM'
            console.error(error)
            sendMail()
            return error
        }
        fileCheck = JSON.parse(file.toString())
    } else {
        error = 'UNINTIALISED WEBSITE'
        console.warn(error)
        sendMail()
        return error
    }
    verifyDirectory(process.argv[3])
    for (let key in fileCheck) {
        errors[key] = 'FILE NOT FOUND'
    }
    if (Object.keys(errors).length) {
        error = 'VERIFICATION FAILED'
        console.error(errors)
        console.error(error)
        sendMail()
    } else
        console.log('VERIFICATION SUCCESSFUL')
}
verify()

function verifyDirectory(r) {
    const stats = fs.statSync(r)
    if (stats?.isFile()) {
        const response = verificationService(process.argv[3], r)
        if (response !== 'TRUE') errors[r] = response
        delete fileCheck[r]
    } else if (stats?.isDirectory()) {
        const directory = fs.readdirSync(r)
        for (let i = 0; i < directory.length; i++)
            verifyDirectory(`${r}/${directory[i]}`)
    }
}
function sendMail() {
    sendEmail({
        subject: error + ' on ' + process.argv[3],
        html: `<div>Dear Admin,</div><div>Verification failed for ${process.argv[3]}</div> <div>Details of the verification is shown below.</div> <div>${error}<br />${JSON.stringify(errors)}</div><div>Best regards</div><div>WDD Team</div>`
    })
}