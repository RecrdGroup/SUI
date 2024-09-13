#!/bin/bash

# check dependencies are available.
for i in jq curl sui; do
  if ! command -V ${i} 2>/dev/null; then
    echo "${i} is not installed"
    exit 1
  fi
done

source .env

publish_res=$(sui client upgrade --skip-dependency-verification --gas-budget 200000000 --upgrade-capability $RECRD_UPGRADE_CAP --json ../move_v2)

echo ${publish_res} >.publish_upgrade.res.json

if [[ "$publish_res" =~ "error" ]]; then
  # If yes, print the error message and exit the script
  echo "Error during move contract upgrade.  Details : $publish_res"
  exit 1
fi

echo "Contract Upgrade finished!"

publishedObjs=$(echo "$publish_res" | jq -r '.objectChanges[] | select(.type == "published")')
DIGEST=$(echo "$publish_res" | jq -r '.digest')
PACKAGE_ID=$(echo "$publishedObjs``" | jq -r '.packageId')

cat >.env.upgrade <<-UPGRADE_ENV
NEW_PACKAGE_ID=$PACKAGE_ID
DIGEST_V2=$DIGEST
UPGRADE_ENV