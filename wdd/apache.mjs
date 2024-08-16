import { sendEmail } from "./notification";
import verificationService from "./verificationService.mjs";

const root = process.argv[2].split(process.argv[3])[0]
const response = verificationService(root, process.argv[2])
if (!['TRUE', 'UNINTIALISED WEBSITE'].includes(response)) {
    console.log('false')
    sendEmail({
        subject: response + ' on ' + process.argv[2],
        html: `<div>Dear Admin,</div><div>Verification failed for ${process.argv[2]}</div> <div>Details of the verification is shown below.</div> <div>${response}<div>Best regards</div><div>WDD Team</div>`
    })
}