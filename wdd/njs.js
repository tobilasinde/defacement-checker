import fs from 'fs'
import verificationService from "./verificationService.mjs"

let res = ''
function verify(r, data, flag) {
    res += data
    if (r.headersOut['Resource-Status']) res = null
    else {
        if (!res && r.variables.request_filename) res = fs.readFileSync(r.variables.request_filename)
        r.done()
    }
    r.sendBuffer(res, flag)
}
function header(r) {
    const response = verificationService(r.variables.document_root, r.variables.request_filename)
    if (!['TRUE', 'UNINTIALISED WEBSITE'].includes(response)) {
        console.error(`${r.variables.request_filename} has been modified`)
        r.status = 403
        r.headersOut['Resource-Status'] = response
        delete r.headersOut['Content-Length']
        // const error = {}
        // error[r.variables.request_filename] = response
        // global.notification.sendEmail({
        // 	to: 'anthony.olasinde@yahoo.com',
        // 	subject: website_name + 'verification failed',
        // 	html: `<div>Dear Admin,</div><div>Verification failed for ${website_name}</div> <div>Details of the verification is shown below.</div> <div>${JSON.stringify(error)}</div><div>Best regards</div><div>WDD Team</div>`
        // })
    }
}
export default { verify, header }