
const fs = require('fs')
const crypto = require('crypto')

const TDC_DIR = '/usr/lib/tdc'
const generateHash = (text) => {
    const hash = crypto.createHash('sha256')
    hash.update(text)
    return hash.digest('hex')
}
const getInitialHash = (fullpath, filename) => {
    let response = "true"
    let root = fullpath.split(filename)[0]
    root = root.replace(/\//g, '_')
    const file_path = `${TDC_DIR}/hashes/${root}.json`
    if (fs.existsSync(file_path)) {
        let file = fs.readFileSync(file_path)
        file = file.toString()
        file = JSON.parse(file)
        if (file[fullpath]) {
            const initalHash = file[fullpath]
            const responseBody = fs.readFileSync(fullpath)
            const hash = generateHash(responseBody)
            if (hash !== initalHash)
                response = "false"
        }
    }
    return response
}
console.log(getInitialHash(process.argv[2], process.argv[3]))