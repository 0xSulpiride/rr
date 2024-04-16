const crypto = require('crypto')
const assert = require('assert')
const Secp256k1 = require('@lionello/secp256k1-js')

// Generating private key
const privateKeyBuf = "0101010101010101010101010101010101010101010101010101010101010101";
const privateKey = Secp256k1.uint256(privateKeyBuf, 16)

console.log(`Private key: ${privateKey}`);
// Generating public key
const publicKey = Secp256k1.generatePublicKeyFromPrivateKeyData(privateKey)
console.log(`Public key: ${JSON.stringify(publicKey, undefined, 2)}`);