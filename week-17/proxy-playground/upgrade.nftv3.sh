#!/bin/sh

source .env

forge script UpgradeV3NFT --broadcast \
    --fork-url $RPC \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --sender $ADDR
