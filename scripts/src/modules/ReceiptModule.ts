// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Signer } from "@mysten/sui.js/cryptography";
import { SuiObjectChangeCreated } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { ADMIN_CAP, PACKAGE_ID, REGISTRY, suiClient } from "../config";
import { executeTransaction, getMasterT } from "../utils";

export class ReceiptModule {
  /// Issue a new Receipt for user that wants to buy a Master
  async newReceipt(
    masterId: string,
    buyerProfileId: string,
    sellerProfileId: string,
    signer: Signer
  ): Promise<SuiObjectChangeCreated> {
    // Create a transaction block
    const txb = new TransactionBlock();

    const masterRes = await suiClient.getObject({
      id: masterId,
      options: { showContent: true },
    });

    const content: any = masterRes.data?.content;
    const masterType = getMasterT(content.type);

    // First, we need to borrow the Master from the Profile of the seller.
    let [master, promise] = txb.moveCall({
      target: `${PACKAGE_ID}::profile::borrow_master`,
      arguments: [
        txb.object(sellerProfileId),
        txb.receivingRef({
          digest: masterRes.data?.digest!,
          objectId: masterId,
          version: masterRes.data?.version!,
        }),
      ],
      typeArguments: [masterType!],
    });

    // We invoke the receipt::new function and pass the master as a witness.
    // The invocation of this function assumes that the buyer has paid off chain.
    // Therefore the BE is responsible for validating the payment and creating the receipt.
    txb.moveCall({
      target: `${PACKAGE_ID}::receipt::new`,
      arguments: [
        txb.object(ADMIN_CAP),
        master,
        txb.pure(buyerProfileId),
        txb.object(REGISTRY),
      ],
      typeArguments: [masterType!],
    });

    // Return the updated Master object to the Profile and resolve the promise.
    txb.moveCall({
      target: `${PACKAGE_ID}::profile::return_master`,
      arguments: [txb.object(master), promise],
      typeArguments: [masterType!],
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
