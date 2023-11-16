const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const fs = require("fs");
const { resolve } = require("path");

const treeJson = resolve(__dirname, "tree.json");

// (1)
const tree = StandardMerkleTree.load(JSON.parse(fs.readFileSync(treeJson)));

// (2)
for (const [i, v] of tree.entries()) {
  if (v[0] === "0x0000000000000000000000000000000000001337") {
    // (3)
    const proof = tree.getProof(i);
    console.log("Value:", v);
    console.log("Proof:", proof);
  }
}