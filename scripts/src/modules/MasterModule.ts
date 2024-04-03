// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { SuiObjectChangeCreated, SuiObjectRef } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { executeTransaction, getMasterT, getMasterMetadataT } from "../utils";
import { PACKAGE_ID, ADMIN_CAP, suiClient } from "../config";
import { SUI_FRAMEWORK_ADDRESS } from "@mysten/sui.js/utils";
import { Master, MasterMetadata } from "../interfaces";
import { Signer } from "@mysten/sui.js/cryptography";

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
  async mintMaster( params: mintMasterParams, signer: Signer ): Promise<mintMasterResponse> {
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
    const response = await executeTransaction({ txb, signer });

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

  /// Burn a Master object by its ID (admin only)
  async burnMaster( masterId: string, signer: Signer ): Promise<SuiObjectRef | undefined> {
    // Get the Master type 
    const masterRes = await suiClient.getObject({ 
      id: masterId,
      options: { showContent: true }
    });

    const content: any = masterRes.data?.content;
    const masterType = getMasterT(content.type);

    // Create a transaction block
    const txb = new TransactionBlock();

    // Call the smart contract function to burn a Master object
    txb.moveCall({
      target: `${PACKAGE_ID}::master::admin_burn_master`,
      arguments: [ txb.object(ADMIN_CAP), txb.object(masterId) ],
      typeArguments: [ masterType! ],
    });

    // Sign and execute the transaction as the admin
    const res = await executeTransaction({ txb, signer });
    
    if (!res.effects?.deleted) {
      throw new Error("No deleted objects were found in the SuiTransactionBlockResponse.");
    }

    // Find the deleted object in the response
    let deletedObject = res.effects.deleted.find(deletedObject => deletedObject.objectId === masterId);
    
    if (!deletedObject) {
      throw new Error("Master object could not be burned.");
    }

    console.log("Master burned successfully:", deletedObject);

    return deletedObject;
  }

  /// Burn a Master Metadata object by its ID (admin only)
  async burnMasterMetadata( metadataId: string, signer: Signer ): Promise<SuiObjectRef | undefined> {
    // Get the Master Metadata type 
    const metadataRes = await suiClient.getObject({ 
      id: metadataId,
      options: { showContent: true }
    });

    const content: any = metadataRes.data?.content;
    const metadataType = getMasterMetadataT(content.type);

    // Create a transaction block
    const txb = new TransactionBlock();

    // Call the smart contract function to burn a Master Metadata object
    txb.moveCall({
      target: `${PACKAGE_ID}::master::admin_burn_metadata`,
      arguments: [ txb.object(ADMIN_CAP), txb.object(metadataId) ],
      typeArguments: [ metadataType! ],
    });

    // Sign and execute the transaction as the admin
    const res = await executeTransaction({ txb, signer });
    
    if (!res.effects?.deleted) {
      throw new Error("No deleted objects were found in the SuiTransactionBlockResponse.");
    }

    // Find the deleted object in the response
    let deletedObject = res.effects.deleted.find(deletedObject => deletedObject.objectId === metadataId);
    
    if (!deletedObject) {
      throw new Error("Master Metadata object could not be burned.");
    }

    console.log("Metadata burned successfully:", deletedObject);

    return deletedObject;
  }
}