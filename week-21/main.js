const { ECmultiply, constants } = require('./secp256k1');

/** PUBLIC KEY GENERATION */
const privateKey = BigInt("0x8ce692b4f19063218579051d319a2ca091e97bda3b7c132894d3ae3c6f541bc5");
console.log(`Private key: ${privateKey}`);
const publicKey = ECmultiply(constants.G, privateKey);
console.log("Public key:", {
  x: publicKey[0].toString(16),
  y: publicKey[1].toString(16)
});

/** SIGNATURE GENERATION */
const { utils } = require('ethers');
/*
const nonce = BigInt(1);
const message = 'some message to hash';
console.log('hashing:', message);
hash.update(message);
const tosign = BigInt(`0x${hash.digest('hex')}`);
const signature = sign(privateKey, tosign, nonce);
console.log(`Verify: ${verify(publicKey, signature, tosign)}`);
*/
// const concat_x_y = '0x' + publicKey[0].toString(16) + publicKey[1].toString(16);
const concat_x_y = utils.hexConcat([
  utils.hexlify(publicKey[0]),
  utils.hexlify(publicKey[1])
]);
const address = utils.keccak256(concat_x_y).slice(-40);
console.log(`Address: 0x${address}`);
