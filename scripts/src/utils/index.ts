// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { suiClient } from "../config";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { Signer } from "@mysten/sui.js/dist/cjs/cryptography";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { fromB64 } from "@mysten/sui.js/utils";

interface ExecuteTransactionParams {
  txb: TransactionBlock; 
  signer: Signer;
}

/// Helper function to sign and execute a transaction with a signer
export const executeTransaction = async ({ txb, signer }: ExecuteTransactionParams) => {
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

/// Helper function to get the Sui address from a private key
export const getSuiAddress = (secretKey: string) => {
  const keypair = getSigner(secretKey);
  return keypair.getPublicKey().toSuiAddress();
};


  /// Get the <T> type of a Master object
  export const getMasterT = ( type: string ): string | null => {
    const regex = /Master<(.+)>/;
    const match = type.match(regex);
    return match ? match[1] : null;
  }