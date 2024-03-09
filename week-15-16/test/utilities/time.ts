const { ethers } = require("hardhat")

export async function advanceBlock() {
  return ethers.provider.send("evm_mine", [])
}

export async function advanceBlockTo(blockNumber: number) {
  for (let i = await ethers.provider.getBlockNumber(); i < blockNumber; i++) {
    await advanceBlock()
  }
}

export async function increase(value: bigint) {
  await ethers.provider.send("evm_increaseTime", [Number(value)])
  await advanceBlock()
}

export async function latest() {
  const block = await ethers.provider.getBlock("latest")
  return BigInt(block.timestamp)
}

export async function advanceTimeAndBlock(time: any) {
  await advanceTime(time)
  await advanceBlock()
}

export async function advanceTime(time: any) {
  await ethers.provider.send("evm_increaseTime", [time])
}

export const duration = {
  seconds: function (val: string | number | bigint | boolean) {
    return BigInt(val)
  },
  minutes: function (val: string | number | bigint | boolean) {
    return BigInt(val) * BigInt(this.seconds("60"))
  },
  hours: function (val: string | number | bigint | boolean) {
    return BigInt(val) * BigInt(this.minutes("60"))
  },
  days: function (val: string | number | bigint | boolean) {
    return BigInt(val) * BigInt(this.hours("24"))
  },
  weeks: function (val: string | number | bigint | boolean) {
    return BigInt(val) * BigInt(this.days("7"))
  },
  years: function (val: string | number | bigint | boolean) {
    return BigInt(val) * BigInt(this.days("365"))
  },
}
