import fs from 'fs'
import generateHash from './generateHash.mjs'

const WDD_DIR = '/usr/lib/wdd'
const verificationService = (root, filename, file_content) => {
    const hash_file = root.replace(/\//g, '_')
    const file_path = `${WDD_DIR}/hashes/${hash_file}.json`
    let initalHash
    if (fs.existsSync(file_path) && fs.existsSync(filename)) {
        //get stored hash
        var file = fs.readFileSync(file_path)
        file = file.toString()
        file = JSON.parse(file)
        if (file[filename]) initalHash = file[filename]
        else return 'ILLEGAL FILE'

        //compare stored hash with resource hash
        if (file_content) {
            const hash = generateHash(file_content)
            if (hash === initalHash) return 'TRUE'
            else return 'ALTERED FILE'
        }
        else if (fs.existsSync(filename)) {
            const file = fs.readFileSync(filename)
            const hash = generateHash(file)
            if (hash === initalHash) return 'TRUE'
            else return 'ALTERED FILE'
        }
    } else return 'UNINTIALISED WEBSITE'
}
export default verificationService
