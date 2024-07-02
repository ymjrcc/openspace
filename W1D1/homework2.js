import crypto from 'crypto'
import forge from 'node-forge'

// 生成符合 hash 开头为 0000 的 message，即 name + nonce
const name = 'ymjrcc'
let count = 0
let result = ''
let message = ''

const getHashResult = (data, nonce) => {
  const hash = crypto.createHash('sha256')
  hash.update(data + nonce)
  return hash.digest('hex')
}

while (!result.startsWith('0000')) {
  result = getHashResult(name, count)
  count++
}
message = name + (count-1)
console.log('message: ', message)

// 生成一対公私钥
const keypair = forge.pki.rsa.generateKeyPair({bits: 2048, e: 0x10001})

// 对 message 进行签名
const md = forge.md.sha256.create()
md.update(message, 'utf8')
const signature = keypair.privateKey.sign(md)

// 验证签名
const verified = keypair.publicKey.verify(md.digest().bytes(), signature);
console.log('verified:', verified)