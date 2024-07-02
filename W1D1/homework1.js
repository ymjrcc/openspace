import crypto from 'crypto'

const name = 'ymjrcc'
let count = 0
let result = ''

const getHashResult = (data, nonce) => {
  const hash = crypto.createHash('sha256')
  hash.update(data + nonce)
  return hash.digest('hex')
}

console.time('time_0000')
while (!result.startsWith('0000')) {
  result = getHashResult(name, count)
  count++
}
console.timeEnd('time_0000')
console.log('str: ', name + (count-1))
console.log('result: ', result)

console.log('------');

console.time('time_00000')
while (!result.startsWith('00000')) {
  result = getHashResult(name, count)
  count++
}
console.timeEnd('time_00000')
console.log('str: ', name + (count-1))
console.log('result: ', result)