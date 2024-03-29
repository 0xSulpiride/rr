#!/bin/sh

source .env

forge script DeployTokenWithGodMode --broadcast \
    --fork-url $RPC \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY
