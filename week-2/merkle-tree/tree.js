const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const fs = require("fs");
const { resolve } = require("path");

const treeJson = resolve(__dirname, "tree.json");

// (1)
const values = [
  ["0x0000000000000000000000000000000000001337", "0"],
  ["0x0000000000000000000000000000000000001338", "1"],
  ["0x0000000000000000000000000000000000000003", "2"],
  ["0x0000000000000000000000000000000000000004", "3"],
  ["0x0000000000000000000000000000000000000005", "4"],
  ["0x0000000000000000000000000000000000000006", "5"],
  ["0x0000000000000000000000000000000000000007", "6"],
  ["0x0000000000000000000000000000000000000008", "7"],
];

// (2)
const tree = StandardMerkleTree.of(values, ["address", "uint256"]);

// (3)
console.log("Merkle Root:", tree.root);

// (4)
fs.writeFileSync(treeJson, JSON.stringify(tree.dump(), undefined, 2));
