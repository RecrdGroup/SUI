// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { SuiObjectChangeCreated } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { executeTransaction, getSigner } from "../utils";
import { RECRD_PRIVATE_KEY, PACKAGE_ID, ADMIN_CAP } from "../config";

interface mintMasterParams {
  type: string;
  title: string;
  description: string;
  image_url: string;
  media_url: string;
  hashtags: string[];
  creator_profile_id: string;
  royalty_percentage_bp: number;
  master_metadata_parent?: string;
  master_metadata_origin?: string;
  sale_status: number;
}

export const VIDEO_TYPE = `${PACKAGE_ID}::master::Video`;
export const AUDIO_TYPE = `${PACKAGE_ID}::master::Audio`;

export class MasterModule {

  /// Mint a new Master object
  async mintMaster( params: mintMasterParams ): Promise<SuiObjectChangeCreated> {
    // Create a transaction block
    const txb = new TransactionBlock();

    // Create an empty option for metadata parent and origin
    const [optionParent] = txb.moveCall({
      target: `0x1::option::none`,
      arguments: [],
      typeArguments: [`${PACKAGE_ID}::object::ID`],
    });

    const [optionOrigin] = txb.moveCall({
      target: `0x1::option::none`,
      arguments: [],
      typeArguments: [`${PACKAGE_ID}::object::ID`],
    });

    // Call the smart contract function to mint a new Master object
    let [master] = txb.moveCall({
      target: `${PACKAGE_ID}::master::new`,
      arguments: [
        txb.object(ADMIN_CAP),
        txb.pure(params.title),
        txb.pure(params.description),
        txb.pure(params.image_url),
        txb.pure(params.media_url),
        txb.pure(params.hashtags),
        txb.pure(params.creator_profile_id),
        txb.pure(params.royalty_percentage_bp),
        optionParent,
        optionOrigin,
        txb.pure(params.sale_status),
      ],
      typeArguments: [ params.type === "Video" ? VIDEO_TYPE : AUDIO_TYPE ],
    });

    txb.setGasBudget(1000000);

    txb.transferObjects([master], params.creator_profile_id);

    // Sign and execute the transaction as the admin
    const response = await executeTransaction({ txb, signer: getSigner(RECRD_PRIVATE_KEY) });
    console.log("Master minting response: ", response);
    // Check if the Master object was minted
    if (!response.effects?.created?.length) {
      throw new Error("Master minting failed or did not return expected result.");
    }

    return response.objectChanges?.find((object) => {
      return object.type === 'created' && object.objectType.startsWith(`master::Master`);
    }) as SuiObjectChangeCreated;
  }
}