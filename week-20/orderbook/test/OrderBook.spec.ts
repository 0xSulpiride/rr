import { expect } from "chai";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { Signer } from "ethers";
import { ethers, network } from "hardhat";
import {
    OrderBook__factory,
    OrderBook,
    MockERC20,
    MockERC20__factory
} from "../typechain-types";

function toWad(value: string): bigint {
    return ethers.parseEther(value); // * 10n ** 18n;
}

describe("OrderBook", async () => {
    let owner: Signer;
    let userA: Signer;
    let userB: Signer;

    let tokenA: MockERC20;
    let tokenB: MockERC20;
    let orderbook: OrderBook;

    let eip712Domain = {};
    let tokenADomain = {};
    let tokenBDomain = {};
    const eip712Types = {
        Order: [
            { name: "trader", type: "address" },
            { name: "deadline", type: "uint256" },
            { name: "price", type: "uint256" },
            { name: "quantity", type: "uint256" },
            { name: "buy", type: "bool" }
        ]
    };
    const tokenTypes = {
        Permit: [
            { name: "owner", type: "address" },
            { name: "spender", type: "address" },
            { name: "value", type: "uint256" },
            { name: "nonce", type: "uint256" },
            { name: "deadline", type: "uint256" }
        ]
    };

    beforeEach(async () => {
        [owner, userA, userB] = await ethers.getSigners();
        const erc20Factory = new MockERC20__factory(owner);
        const orderbookFactory = new OrderBook__factory(owner);
        tokenA = await erc20Factory.deploy("TokenA", "TKNA", 18);
        tokenB = await erc20Factory.deploy("TokenB", "TKNB", 18);
        orderbook = await orderbookFactory.deploy(
            await tokenA.getAddress(),
            await tokenB.getAddress(),
            await owner.getAddress()
        );

        tokenA.connect(userA).mint(ethers.parseEther("1000000"));
        tokenB.connect(userA).mint(ethers.parseEther("1000000"));
        tokenA.connect(userB).mint(ethers.parseEther("1000000"));
        tokenB.connect(userB).mint(ethers.parseEther("1000000"));
        eip712Domain = {
            name: "Orderbook",
            version: "1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: await orderbook.getAddress()
        };
        tokenADomain = {
            name: "TokenA",
            version: "1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: await tokenA.getAddress()
        };
        tokenBDomain = {
            name: "TokenB",
            version: "1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: await tokenB.getAddress()
        };
    });

    it("should execute order", async () => {
        await tokenA
            .connect(userA)
            .approve(await orderbook.getAddress(), ethers.parseEther("1000"));
        await tokenB
            .connect(userA)
            .approve(await orderbook.getAddress(), ethers.parseEther("1000"));
        await tokenA
            .connect(userB)
            .approve(await orderbook.getAddress(), ethers.parseEther("1000"));
        await tokenB
            .connect(userB)
            .approve(await orderbook.getAddress(), ethers.parseEther("1000"));

        const time = (await ethers.provider.getBlock("latest"))?.timestamp!;
        const sellOrder = {
            trader: await userA.getAddress(),
            deadline: time + 1000,
            price: toWad("2"),
            quantity: ethers.parseEther("500"),
            buy: false
        }; // will get 1000 token A
        const buyOrder = {
            trader: await userB.getAddress(),
            deadline: time + 1000,
            price: toWad("2.1"),
            quantity: ethers.parseEther("200"),
            buy: true
        };

        const sellSignature = await userA.signTypedData(
            eip712Domain,
            eip712Types,
            sellOrder
        );

        const buySignature = await userB.signTypedData(
            eip712Domain,
            eip712Types,
            buyOrder
        );

        await expect(
            orderbook
                .connect(owner)
                .execute(sellOrder, sellSignature, buyOrder, buySignature)
        )
            .to.emit(orderbook, "Executed")
            .withArgs(
                anyValue,
                anyValue,
                buyOrder.quantity,
                (ethers.parseEther("200") * 10n) / 21n
            );
    });

    it("should call multicall with permits and execute order", async () => {
        const time = (await ethers.provider.getBlock("latest"))?.timestamp!;
        const aApproveTokenA = {
            owner: await userA.getAddress(),
            spender: await orderbook.getAddress(),
            value: ethers.parseEther("1000"),
            nonce: await tokenA.nonces(await userA.getAddress()),
            deadline: time + 1000
        };
        const aApproveTokenASignature = ethers.Signature.from(
            await userA.signTypedData(tokenADomain, tokenTypes, aApproveTokenA)
        );
        const aApproveTokenB = {
            owner: await userA.getAddress(),
            spender: await orderbook.getAddress(),
            value: ethers.parseEther("1000"),
            nonce: await tokenB.nonces(await userA.getAddress()),
            deadline: time + 1000
        };
        const aApproveTokenBSignature = ethers.Signature.from(
            await userA.signTypedData(tokenBDomain, tokenTypes, aApproveTokenB)
        );
        const bApproveTokenA = {
            owner: await userB.getAddress(),
            spender: await orderbook.getAddress(),
            value: ethers.parseEther("1000"),
            nonce: await tokenA.nonces(await userB.getAddress()),
            deadline: time + 1000
        };
        const bApproveTokenASignature = ethers.Signature.from(
            await userB.signTypedData(tokenADomain, tokenTypes, bApproveTokenA)
        );
        const bApproveTokenB = {
            owner: await userB.getAddress(),
            spender: await orderbook.getAddress(),
            value: ethers.parseEther("1000"),
            nonce: await tokenB.nonces(await userB.getAddress()),
            deadline: time + 1000
        };
        const bApproveTokenBSignature = ethers.Signature.from(
            await userB.signTypedData(tokenBDomain, tokenTypes, bApproveTokenB)
        );
        const sellOrder = {
            trader: await userA.getAddress(),
            deadline: time + 1000,
            price: toWad("2"),
            quantity: ethers.parseEther("500"),
            buy: false
        };
        const buyOrder = {
            trader: await userB.getAddress(),
            deadline: time + 1000,
            price: toWad("2.1"),
            quantity: ethers.parseEther("200"),
            buy: true
        };
        const sellSignature = await userA.signTypedData(
            eip712Domain,
            eip712Types,
            sellOrder
        );

        const buySignature = await userB.signTypedData(
            eip712Domain,
            eip712Types,
            buyOrder
        );

        await expect(
            orderbook
                .connect(owner)
                .multicall([
                    orderbook.interface.encodeFunctionData("permitERC20", [
                        await tokenA.getAddress(),
                        aApproveTokenA.owner,
                        aApproveTokenA.value,
                        aApproveTokenA.deadline,
                        aApproveTokenASignature.v,
                        aApproveTokenASignature.r,
                        aApproveTokenASignature.s
                    ]),
                    orderbook.interface.encodeFunctionData("permitERC20", [
                        await tokenB.getAddress(),
                        aApproveTokenB.owner,
                        aApproveTokenB.value,
                        aApproveTokenB.deadline,
                        aApproveTokenBSignature.v,
                        aApproveTokenBSignature.r,
                        aApproveTokenBSignature.s
                    ]),
                    orderbook.interface.encodeFunctionData("permitERC20", [
                        await tokenA.getAddress(),
                        bApproveTokenA.owner,
                        bApproveTokenA.value,
                        bApproveTokenA.deadline,
                        bApproveTokenASignature.v,
                        bApproveTokenASignature.r,
                        bApproveTokenASignature.s
                    ]),
                    orderbook.interface.encodeFunctionData("permitERC20", [
                        await tokenB.getAddress(),
                        bApproveTokenB.owner,
                        bApproveTokenB.value,
                        bApproveTokenB.deadline,
                        bApproveTokenBSignature.v,
                        bApproveTokenBSignature.r,
                        bApproveTokenBSignature.s
                    ]),
                    orderbook.interface.encodeFunctionData("execute", [
                        sellOrder,
                        sellSignature,
                        buyOrder,
                        buySignature
                    ])
                ])
        )
            .to.emit(orderbook, "Executed")
            .withArgs(
                anyValue,
                anyValue,
                buyOrder.quantity,
                (ethers.parseEther("200") * 10n) / 21n
            );
    });
});
