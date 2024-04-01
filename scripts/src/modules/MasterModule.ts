// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { SuiObjectChangeCreated } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { executeTransaction, getSigner } from "../utils";
import { RECRD_PRIVATE_KEY, PACKAGE_ID, ADMIN_CAP, suiClient } from "../config";
import { SUI_FRAMEWORK_ADDRESS } from "@mysten/sui.js/utils";
import { Master, MasterMetadata } from "../interfaces";

export interface mintMasterParams {
  type: "Video" | "Audio";
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

interface mintMasterResponse {
  master: SuiObjectChangeCreated | undefined;
  metadata: SuiObjectChangeCreated | undefined;
}

export const VIDEO_TYPE = `${PACKAGE_ID}::master::Video`;
export const AUDIO_TYPE = `${PACKAGE_ID}::master::Audio`;

export class MasterModule {

  /// Mint a new Master object
  async mintMaster( params: mintMasterParams ): Promise<mintMasterResponse> {
    // Create a transaction block
    const txb = new TransactionBlock();

    // Create an empty option for metadata parent and origin
    const none = txb.moveCall({
      target: `0x1::option::none`,
      arguments: [],
      typeArguments: [`${SUI_FRAMEWORK_ADDRESS}::object::ID`],
    });

    // Call the smart contract function to mint a new Master object
    let masterTx = txb.moveCall({
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
        none,
        none,
        txb.pure(params.sale_status),
      ],
      typeArguments: [ params.type === "Video" ? VIDEO_TYPE : AUDIO_TYPE ],
    });

    txb.transferObjects([masterTx], params.creator_profile_id);

    // Sign and execute the transaction as the admin
    const response = await executeTransaction({ txb, signer: getSigner(RECRD_PRIVATE_KEY) });

    let master, metadata;

    // Iterate through objectChanges to find Master and Metadata objects
    response.objectChanges?.forEach((change) => {
      if (change.type === 'created') {
        if (change.objectType.includes('::master::Master')) {
          master = change;
        } else if (change.objectType.includes('::master::Metadata')) {
          metadata = change;
        }
      }
    });

    if (!master || !metadata) {
      throw new Error("Master or Metadata object creation not found in response.");
    }

    // Return the created Master and Metadata objects
    return { master, metadata };
  }

  /// Query a Master object by its ID and return the object
  async getMasterById( masterId: string ): Promise<Master> {
    // Retrieve the Master object
    const masterRes = await suiClient.getObject({
      id: masterId, 
      options: { showContent: true } 
    });

    const content: any = masterRes.data?.content;

    return {
      id: content?.fields.id.id,
      type: content?.type,
      metadataRef: content?.fields.metadata_ref,
      title: content?.fields.title,
      imageUrl: content?.fields.image_url,
      mediaUrl: content?.fields.media_url,
      saleStatus: content?.fields.sale_status,
    }
  }

  /// Query a Master Metadata object by its ID and return the object
  async getMasterMetadataById( metadataId: string ): Promise<MasterMetadata> {
    // Retrieve the Master Metadata object
    const metadataRes = await suiClient.getObject({
      id: metadataId, 
      options: { showContent: true } 
    });

    const content: any = metadataRes.data?.content;

    return {
      id: metadataRes.data?.objectId!,
      masterId: content?.fields.master_id,
      title: content?.fields.title,
      description: content?.fields.description,
      imageUrl: content?.fields.image_url,
      mediaUrl: content?.fields.media_url,
      hashtags: content?.fields.hashtags,
      creatorProfileId: content?.fields.creator_profile_id,
      royaltyPercentageBp: content?.fields.royalty_percentage_bp,
      parent: content?.fields.parent ?? null,
      origin: content?.fields.origin ?? null,
      expressions: content?.fields.expressions,
      revenueTotal: content?.fields.revenue_total,
      revenueAvailable: content?.fields.revenue_available,
      revenuePaid: content?.fields.revenue_paid,
      revenuePending: content?.fields.revenue_pending,
    }
  }
}