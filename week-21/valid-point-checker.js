const { ECmultiply, constants } = require('./secp256k1');

/**
 * @param point x and y
 * @return {Boolean} returns true if point belongs to curve y^2 = x^3 + 7
 */
function isValidPoint(point) {
  const rem = (point.y ** 2n - point.x ** 3n - constants.B) % constants.P;
  return rem == 0n;
}

for (let i = 1n; i < 10n; ++i) {
  const point = ECmultiply(constants.G, i);
  point.x = point[0];
  point.y = point[1];
  console.log(`Generator * ${i} is valid? ${isValidPoint(point)}`);
}
