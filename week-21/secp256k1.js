const constants = {
  P: BigInt("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F"),
  A: BigInt("0x0000000000000000000000000000000000000000000000000000000000000000"),
  B: BigInt("0x0000000000000000000000000000000000000000000000000000000000000007"),
  G: [
    BigInt("0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"),
    BigInt("0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8"),
  ],
  N: BigInt("0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"),
  H: BigInt("0x1"),
}

/**
 * returns positive a % b
 * @param {*} a big int
 * @param {*} b big int
 * @returns a % b
 */
function modBn(a, b) {
  return (a % b + b) % b;
}

/**
 * Extended Euclidean Algorithm
 * @return {BigInt} modular inverse of a
 */
function modinv(a, n = constants.P) {
  let lm = 1n, hm = 0n;
  let low = modBn(a, n), high = n;
  while (low > 1n) {
    ratio = high / low;
    let nm = (hm - lm * ratio), new_low = (high - low * ratio);
    [lm, low, hm, high] = [nm, new_low, lm, low];
  }
  return modBn(lm, n);
}

/**
 * Elliptic curve addition
 * @param {Array<BigInt>} a point on a curve
 * @param {Array<BigInt>} b point on a curve
 * @return {Array<BigInt>} new point on a curve
 */
function ECadd(a, b) {
  let LamAdd = modBn((b[1] - a[1]) * modinv(b[0] - a[0]), constants.P);
  x = modBn(LamAdd * LamAdd - a[0] - b[0],  constants.P);
  y = modBn(LamAdd * (a[0] - x) - a[1], constants.P);
  return [x, y];
}

/**
 * Point doubling
 * @param {Array<BigInt>} a point on a curve
 * @returns {Array<BigInt>} new point
 */
function ECdouble(a) {
  let Lam = modBn((3n * a[0] * a[0] + constants.A) * modinv(2n * a[1]), constants.P);
  x = modBn(Lam * Lam - 2n * a[0], constants.P);
  y = modBn(Lam * (a[0] - x) - a[1], constants.P);
  return [x, y];
}

/**
 * Elliptic curve multiply
 * @param {Array<BigInt>} generator generator point
 * @param {BigInt} scalar scalar value
 * @returns point on a curve
 */
function ECmultiply(generator, scalar) {
  if (scalar == 0n || scalar >= constants.N) throw Error("Invalid Scalar/Private key");
  const scalarBin = scalar.toString(2);
  let nowPoint = null;
  let nextPoint = generator;
  for (let i = scalarBin.length - 1; i >= 0; --i) {
    if (scalarBin[i] == '1') {
      if (nowPoint == null) {
        nowPoint = nextPoint;
      } else {
        nowPoint = ECadd(nowPoint, nextPoint);
      }
    }
    nextPoint = ECdouble(nextPoint);
  }
  return nowPoint;
}

/**
 * sign hash with your private key
 * @param privateKey private key
 * @param hash hash of a message to sign
 * @param nonce nonce
 * @returns r, s
 */
function sign(privateKey, hash, nonce) {
  const [x, y] = ECmultiply(constants.G, nonce);
  const r = modBn(x, constants.N);
  const s = modBn((hash + r * privateKey) * modinv(nonce, constants.N), constants.N);
  return { r, s };
}

function verify(pk, signature, hash) {
  const w = modinv(signature.s, constants.N);
  const [xu1, yu1] = ECmultiply(constants.G, modBn(hash * w, constants.N));
  const [xu2, yu2] = ECmultiply(pk, modBn(signature.r * w, constants.N));
  const [x, y] = ECadd([xu1, yu1], [xu2, yu2]);
  return signature.r == x;
}

module.exports = {
  ECadd,
  ECmultiply,
  constants,
  sign,
  verify,
}