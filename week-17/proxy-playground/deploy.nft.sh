#!/bin/sh

source .env

forge script DeployWhitelistDiscountNFT --broadcast \
    --fork-url $RPC \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY
