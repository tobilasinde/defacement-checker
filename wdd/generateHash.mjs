import crypto from 'crypto'

const generateHash = (text) => {
    const hash = crypto.createHash('sha256')
    hash.update(text)
    return hash.digest('hex')
}
export default generateHash