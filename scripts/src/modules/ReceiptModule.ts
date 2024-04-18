// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Signer } from "@mysten/sui.js/cryptography";
import { SuiObjectChangeCreated } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { ADMIN_CAP, PACKAGE_ID, REGISTRY } from "../config";
import { executeTransaction } from "../utils";

export class ReceiptModule {
  /// Issue a new Receipt for user that wants to buy a Master
  async newReceipt(
    masterId: string,
    profileId: string,
    signer: Signer
  ): Promise<SuiObjectChangeCreated> {
    // Create a transaction block
    const txb = new TransactionBlock();

    txb.moveCall({
      target: `${PACKAGE_ID}::receipt::new`,
      arguments: [
        txb.object(ADMIN_CAP),
        txb.pure(masterId),
        txb.pure(profileId),
        txb.object(REGISTRY),
      ],
    });

    // Sign and execute the transaction as the admin
    const response = await executeTransaction({ txb, signer });
    let receipt;

    // Iterate through objectChanges to find the Receipt object
    response.objectChanges?.forEach((change) => {
      if (
        change.type === "created" &&
        change.objectType.includes("::receipt::Receipt")
      ) {
        receipt = change;
      }
    });

    if (!receipt) {
      throw new Error("Receipt object creation not found in response.");
    }

    // Return the created Receipt object
    return receipt;
  }
}
