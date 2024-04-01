#!/bin/bash

# check dependencies are available.
for i in jq curl sui; do
  if ! command -V ${i} 2>/dev/null; then
    echo "${i} is not installed"
    exit 1
  fi
done

NETWORK=http://localhost:9000

MOVE_PACKAGE_PATH=../move

if [ $# -ne 0 ]; then
  if [ $1 = "testnet" ]; then
    NETWORK="https://fullnode.testnet.sui.io:443"
  fi
  if [ $1 = "devnet" ]; then
    NETWORK="https://fullnode.devnet.sui.io:443"
  fi
fi

PRIVATE_KEY=$(cat ~/.sui/sui_config/sui.keystore | jq -r '.[0]')

switch_res=$(sui client switch --address ${ADMIN_ADDRESS})

publish_res=$(sui client publish --skip-fetch-latest-git-deps --gas-budget 2000000000 --json ${MOVE_PACKAGE_PATH})

echo ${publish_res} >.publish.res.json

# Check if the command succeeded (exit status 0)
if [[ "$publish_res" =~ "error" ]]; then
  # If yes, print the error message and exit the script
  echo "Error during move contract publishing.  Details : $publish_res"
  exit 1
fi

publishedObjs=$(echo "$publish_res" | jq -r '.objectChanges[] | select(.type == "published")')
DIGEST=$(echo "$publish_res" | jq -r '.digest')
PACKAGE_ID=$(echo "$publishedObjs" | jq -r '.packageId')

newObjs=$(echo "$publish_res" | jq -r '.objectChanges[] | select(.type == "created")')

ADMIN_CAP_ID=$(echo "$newObjs" | jq -r 'select (.objectType | contains("core::AdminCap")).objectId')
UPGRADE_CAP_ID=$(echo "$newObjs" | jq -r 'select (.objectType | contains("::package::UpgradeCap")).objectId')
PUBLISHER=$(echo "$newObjs" | jq -r 'select (.objectType | contains("package::Publisher")).objectId')

cat >.env<<-ENV
SUI_NETWORK=$NETWORK
DIGEST=$DIGEST
RECRD_PACKAGE_ID=$PACKAGE_ID
RECRD_UPGRADE_CAP=$UPGRADE_CAP_ID
CORE_ADMIN_CAP=$ADMIN_CAP_ID
PUBLISHER=$PUBLISHER
RECRD_PRIVATE_KEY=$PRIVATE_KEY
USER_PRIVATE_KEY=
ENV

echo "Contract Deployment finished!"