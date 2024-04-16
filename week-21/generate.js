const { hexConcat } = require('ethers/lib/utils');
const { ECmultiply, constants } = require('./secp256k1');
const { utils } = require('ethers');

let privateKey = BigInt("0x8ce692b4f19063218579051d319a2ca091e97bda3b7c132894d3ae3c6f3fa6a6");
for (let i = 1n; i < 65536n; ++i) {
    const publicKey = ECmultiply(constants.G, privateKey);
    const concat_x_y = utils.hexConcat([
        utils.hexlify(publicKey[0]),
        utils.hexlify(publicKey[1])
    ]);
    const address = utils.keccak256(concat_x_y).slice(-40);
    if (address.startsWith('0000')) {
        console.log(`Found private key:$ ${privateKey.toString(16)}`);
        console.log(`Adddress: 0x${address}`);
        return;
    }
    privateKey += i;
    if (i % 500n == 0) {
        console.log("Searching...");
    }
}
console.log('Could not find private key :(');

/**
 * Output:
 * Searching...
 * Searching...
 * Searching...
 * Found private key: 8ce692b4f19063218579051d319a2ca091e97bda3b7c132894d3ae3c6f541bc5
 * Address: 0x0000fdb58c648803298b3a522718aaa71ff6e8d3
 */