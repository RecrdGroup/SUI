// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import {
  suiClient,
  DIGEST,
  MASTER_VIDEO_TYPE,
  MASTER_SOUND_TYPE,
  METADATA_VIDEO_TYPE,
  METADATA_SOUND_TYPE,
} from "../config";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { Signer } from "@mysten/sui.js/dist/cjs/cryptography";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { SUI_FRAMEWORK_ADDRESS, fromB64 } from "@mysten/sui.js/utils";
import { SuiObjectChangeCreated } from "@mysten/sui.js/client";

interface ExecuteTransactionParams {
  txb: TransactionBlock;
  signer: Signer;
}

/// Helper function to sign and execute a transaction with a signer
export const executeTransaction = async ({
  txb,
  signer,
}: ExecuteTransactionParams) => {
  return suiClient.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    signer,
    requestType: "WaitForLocalExecution",
    options: {
      showEffects: true,
      showObjectChanges: true,
    },
  });
};

/// Helper function to get the signer from a private key
export const getSigner = (secretKey: string) => {
  let privateKeyArray = Uint8Array.from(Array.from(fromB64(secretKey)));
  const keypair = Ed25519Keypair.fromSecretKey(
    Uint8Array.from(privateKeyArray).slice(1)
  );

  return keypair;
};

/// Helper function to retrieve Display objects from publish txn Digest
export const getDisplayObjects = async () => {
  const txnRes = await suiClient.getTransactionBlock({
    digest: DIGEST,
    options: { showObjectChanges: true },
  });
  const objectChanges = txnRes.objectChanges?.filter(
    (obj) => obj.type === "created"
  ) as SuiObjectChangeCreated[];
  const displayObjects = {
    masterVideoDisplay: objectChanges.find(
      (obj) =>
        obj.objectType ===
        `${SUI_FRAMEWORK_ADDRESS}::display::Display<${MASTER_VIDEO_TYPE}>`
    )?.objectId,
    masterSoundDisplay: objectChanges?.find(
      (obj) =>
        obj.objectType ===
        `${SUI_FRAMEWORK_ADDRESS}::display::Display<${MASTER_SOUND_TYPE}>`
    )?.objectId,
    metadataVideoDisplay: objectChanges?.find(
      (obj) =>
        obj.objectType ===
        `${SUI_FRAMEWORK_ADDRESS}::display::Display<${METADATA_VIDEO_TYPE}>`
    )?.objectId,
    metadataSoundDisplay: objectChanges?.find(
      (obj) =>
        obj.objectType ===
        `${SUI_FRAMEWORK_ADDRESS}::display::Display<${METADATA_SOUND_TYPE}>`
    )?.objectId,
  };
  if (
    !displayObjects.masterVideoDisplay ||
    !displayObjects.masterSoundDisplay ||
    !displayObjects.metadataVideoDisplay ||
    !displayObjects.metadataSoundDisplay
  ) {
    throw new Error("Display object(s) not found");
  }
  return displayObjects;
};

/// Helper function to get the Sui address from a private key
export const getSuiAddress = (secretKey: string) => {
  const keypair = getSigner(secretKey);
  return keypair.getPublicKey().toSuiAddress();
};

/// Get the <T> type of a Master object
export const getMasterT = (type: string): string | null => {
  const regex = /Master<(.+)>/;
  const match = type.match(regex);
  return match ? match[1] : null;
};

/// Get the <T> type of a MasterMetadata object
export const getMasterMetadataT = (type: string): string | null => {
  const regex = /Metadata<(.+)>/;
  const match = type.match(regex);
  return match ? match[1] : null;
};
