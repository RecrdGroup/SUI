// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { SuiObjectChangeCreated, SuiObjectRef } from "@mysten/sui.js/client";
import {
  TransactionBlock,
  TransactionResult,
} from "@mysten/sui.js/transactions";
import { executeTransaction, getMasterT, getMasterMetadataT } from "../utils";
import { PACKAGE_ID, ADMIN_CAP, suiClient } from "../config";
import { SUI_FRAMEWORK_ADDRESS } from "@mysten/sui.js/utils";
import { Master, MasterMetadata } from "../interfaces";
import { Signer } from "@mysten/sui.js/cryptography";
import { SALE_STATUS } from "../config";

export interface mintMasterParams {
  type: "Video" | "Audio";
  title: string;
  description: string;
  image_url: string;
  media_url: string;
  hashtags: string[];
  creator_profile_id: string;
  royalty_percentage_bp: number;
  master_metadata_parent: string;
  master_metadata_origin: string;
  expressions: number;
  revenue_total: number;
  revenue_available: number;
  revenue_paid: number;
  revenue_pending: number;
  sale_status: number;
}

interface mintMasterResponse {
  master: SuiObjectChangeCreated | undefined;
  metadata: SuiObjectChangeCreated | undefined;
}

export const VIDEO_TYPE = `${PACKAGE_ID}::master::Video`;
export const AUDIO_TYPE = `${PACKAGE_ID}::master::Audio`;

export class MasterModule {
  /**
   * Mints a new Master object along with its metadata based on the provided parameters.
   * This function orchestrates the minting process, including transaction handling and
   * object creation.
   *
   * @param params - The parameters required for minting a new Master `mintMasterParams`
   * @param signer - The signer that will sign and execute the transaction.
   * @returns A promise that resolves to an object containing references to the newly
   * created Master and Metadata objects.
   */
  async mintMaster(
    params: mintMasterParams,
    signer: Signer
  ): Promise<mintMasterResponse> {
    // Create a transaction block
    const txb = new TransactionBlock();

    // Prepare empty TransactionResults for meta origin and parent.
    let parent: TransactionResult;
    let origin: TransactionResult;

    // If metadata parent ID is empty string, create empty option.
    if (params.master_metadata_parent.length == 0) {
      parent = txb.moveCall({
        target: `0x1::option::none`,
        arguments: [],
        typeArguments: [`${SUI_FRAMEWORK_ADDRESS}::object::ID`],
      });
    } else {
      // Create an option with given metadata parent ID
      parent = txb.moveCall({
        target: `0x1::option::some`,
        arguments: [txb.pure(params.master_metadata_parent, "address")],
        typeArguments: [`${SUI_FRAMEWORK_ADDRESS}::object::ID`],
      });
    }

    // If metadata origin ID is empty string, create empty option.
    if (params.master_metadata_origin.length == 0) {
      origin = txb.moveCall({
        target: `0x1::option::none`,
        arguments: [],
        typeArguments: [`${SUI_FRAMEWORK_ADDRESS}::object::ID`],
      });
    } else {
      // Create an option with given metadata origin ID
      origin = txb.moveCall({
        target: `0x1::option::some`,
        arguments: [txb.pure(params.master_metadata_origin, "address")],
        typeArguments: [`${SUI_FRAMEWORK_ADDRESS}::object::ID`],
      });
    }

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
        parent,
        origin,
        txb.pure(params.expressions),
        txb.pure(params.revenue_total),
        txb.pure(params.revenue_available),
        txb.pure(params.revenue_paid),
        txb.pure(params.revenue_pending),
        txb.pure(params.sale_status),
      ],
      typeArguments: [params.type === "Video" ? VIDEO_TYPE : AUDIO_TYPE],
    });

    txb.transferObjects([masterTx], params.creator_profile_id);

    // Sign and execute the transaction as the admin
    const response = await executeTransaction({ txb, signer });

    let master, metadata;

    // Iterate through objectChanges to find Master and Metadata objects
    response.objectChanges?.forEach((change) => {
      if (change.type === "created") {
        if (change.objectType.includes("::master::Master")) {
          master = change;
        } else if (change.objectType.includes("::master::Metadata")) {
          metadata = change;
        }
      }
    });

    if (!master || !metadata) {
      throw new Error(
        "Master or Metadata object creation not found in response."
      );
    }

    // Return the created Master and Metadata objects
    return { master, metadata };
  }

  /**
   * Lists a Master for sale by updating its status to 'ON_SALE'.
   * This function internally calls `updateStatus` to update the sale status.
   *
   * @param profileId - The ID for the user profile.
   * @param masterId - The ID for the Master to be listed.
   * @param signer - The signer that will sign and execute the transaction.
   * @returns A promise that resolves with the updated Master object.
   */
  async listMaster(
    profileId: string,
    masterId: string,
    signer: Signer
  ): Promise<Master> {
    return await this.updateStatus(
      profileId,
      masterId,
      SALE_STATUS.ON_SALE,
      signer
    );
  }

  /**
   * Suspends a Master by updating its status to 'SUSPENDED'.
   * This status update is typically in response to a violation or
   * administrative action.
   *
   * @param profileId - The ID for the user profile.
   * @param masterId - The ID for the Master to be listed.
   * @param signer - The signer that will sign and execute the transaction.
   * @returns A promise that resolves with the updated Master object.
   */
  async suspendMaster(profileId: string, masterId: string, signer: Signer) {
    return await this.updateStatus(
      profileId,
      masterId,
      SALE_STATUS.SUSPENDED,
      signer
    );
  }

  /**
   * Reverts a Master's status to 'RETAINED', effectively removing it from active sale
   * without deleting it.
   * This status indicates that the Master is being held but not currently offered
   * for sale.
   *
   * @param profileId - The ID for the user profile.
   * @param masterId - The ID for the Master to be listed.
   * @param signer - The signer that will sign and execute the transaction.
   * @returns A promise that resolves with the updated Master object.
   */
  async retainMaster(profileId: string, masterId: string, signer: Signer) {
    return await this.updateStatus(
      profileId,
      masterId,
      SALE_STATUS.RETAINED,
      signer
    );
  }

  /**
   * Unsuspends a master by updating its status to 'RETAINED'.
   *
   * @param profileId - The ID for the user profile.
   * @param masterId - The ID for the Master to be listed.
   * @param signer - The signer that will sign and execute the transaction.
   * @returns A promise that resolves with the updated Master object.
   */
  async unsuspendMaster(profileId: string, masterId: string, signer: Signer) {
    // Get the Master type
    const masterType = await this.getMasterType(masterId);

    if (!masterType) {
      throw new Error("Couldn't get Master type");
    }

    // Create a transaction block
    const txb = new TransactionBlock();

    // First, we need to borrow the Master from the Profile
    let [master, promise] = txb.moveCall({
      target: `${PACKAGE_ID}::profile::borrow_master`,
      arguments: [txb.object(profileId), txb.object(masterId)],
      typeArguments: [masterType],
    });

    // Unsuspending the master
    txb.moveCall({
      target: `${PACKAGE_ID}::master::unsuspend`,
      arguments: [txb.object(ADMIN_CAP), master],
      typeArguments: [masterType],
    });

    // Return the updated Master object to the Profile and resolve the promise
    txb.moveCall({
      target: `${PACKAGE_ID}::profile::return_master`,
      arguments: [txb.object(master), promise],
      typeArguments: [masterType],
    });

    // Sign and execute the transaction
    const res = await executeTransaction({ txb, signer });
    console.log(res);
    // Check if the profile was updated successfully
    let updatedMaster = res.objectChanges!.find(
      (e) => e.type == "mutated" && e.objectType.includes("Master")
    );

    if (!updatedMaster || updatedMaster.type !== "mutated") {
      throw new Error("Master update failed.");
    }

    return await this.getMasterById(masterId);
  }

  /**
   * Internal function to update the sale status of a Master. It makes the necessary
   * moveCalls to submit transactions.
   *
   * @param profileId - The ID of the user profile associated with the Master.
   * @param masterId - The ID of the Master to update.
   * @param status - The new sale status to be set.
   * @param signer - The signer that will sign and execute the transaction.
   * @returns A promise that resolves with the updated Master object.
   */
  private async updateStatus(
    profileId: string,
    masterId: string,
    status: number,
    signer: Signer
  ): Promise<Master> {
    // Get the Master type
    const masterType = await this.getMasterType(masterId);

    if (!masterType) {
      throw new Error("Couldn't get Master type");
    }

    // Create a transaction block
    const txb = new TransactionBlock();

    // Determine the function name based on the status
    let functionName: string;
    switch (status) {
      case SALE_STATUS.ON_SALE:
        functionName = "list";
        break;
      case SALE_STATUS.SUSPENDED:
        functionName = "suspend";
        break;
      case SALE_STATUS.RETAINED:
        functionName = "unlist";
        break;
      default:
        functionName = "unlist";
        break;
    }

    // First, we need to borrow the Master from the Profile
    let [master, promise] = txb.moveCall({
      target: `${PACKAGE_ID}::profile::borrow_master`,
      arguments: [txb.object(profileId), txb.object(masterId)],
      typeArguments: [masterType],
    });

    // Call the contract to list for sale
    if (status == SALE_STATUS.SUSPENDED) {
      txb.moveCall({
        target: `${PACKAGE_ID}::master::${functionName}`,
        arguments: [txb.object(ADMIN_CAP), master],
        typeArguments: [masterType],
      });
    } else {
      txb.moveCall({
        target: `${PACKAGE_ID}::master::${functionName}`,
        arguments: [master],
        typeArguments: [masterType],
      });
    }

    // Return the updated Master object to the Profile and resolve the promise
    txb.moveCall({
      target: `${PACKAGE_ID}::profile::return_master`,
      arguments: [txb.object(master), promise],
      typeArguments: [masterType],
    });

    // Sign and execute the transaction
    const res = await executeTransaction({ txb, signer });
    console.log(res);
    // Check if the profile was updated successfully
    let updatedMaster = res.objectChanges!.find(
      (e) => e.type == "mutated" && e.objectType.includes("Master")
    );

    if (!updatedMaster || updatedMaster.type !== "mutated") {
      throw new Error("Master update failed.");
    }

    return await this.getMasterById(masterId);
  }

  /**
   * Retrieves a Master object by its ID.
   *
   * @param masterId - The ID of the Master object to retrieve.
   * @returns A promise that resolves to the Master object details if found.
   */
  async getMasterById(masterId: string): Promise<Master> {
    // Retrieve the Master object
    const masterRes = await suiClient.getObject({
      id: masterId,
      options: { showContent: true },
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
    };
  }

  /**
   * Retrieves a Master Metadata object by its ID.
   *
   * @param metadataId - The ID of the Master Metadata to retrieve.
   * @returns A promise that resolves to the Master Metadata object details if found.
   */
  async getMasterMetadataById(metadataId: string): Promise<MasterMetadata> {
    // Retrieve the Master Metadata object
    const metadataRes = await suiClient.getObject({
      id: metadataId,
      options: { showContent: true },
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
    };
  }

  /**
   * Burns a Master object by its ID.
   * Typically used for administrative or compliance reasons.
   * This action is irreversible and should only be performed under specific conditions.
   *
   * @param masterId - The ID of the Master to burn.
   * @param signer - The signer that will sign and execute the transaction.
   * @returns A promise that resolves to a reference to the deleted Master object,
   * if successful.
   */
  async burnMaster(
    masterId: string,
    signer: Signer
  ): Promise<SuiObjectRef | undefined> {
    // Get the Master type
    const masterType = await this.getMasterType(masterId);

    if (!masterType) {
      throw new Error("Couldn't get Master type");
    }

    // Create a transaction block
    const txb = new TransactionBlock();

    // Call the smart contract function to burn a Master object
    txb.moveCall({
      target: `${PACKAGE_ID}::master::burn_master`,
      arguments: [txb.object(ADMIN_CAP), txb.object(masterId)],
      typeArguments: [masterType],
    });

    // Sign and execute the transaction as the admin
    const res = await executeTransaction({ txb, signer });

    if (!res.effects?.deleted) {
      throw new Error(
        "No deleted objects were found in the SuiTransactionBlockResponse."
      );
    }

    // Find the deleted object in the response
    let deletedObject = res.effects.deleted.find(
      (deletedObject) => deletedObject.objectId === masterId
    );

    if (!deletedObject) {
      throw new Error("Master object could not be burned.");
    }

    console.log("Master burned successfully:", deletedObject);

    return deletedObject;
  }

  /**
   * Burns a Master Metadata object by its ID.
   * Typically used for administrative or compliance reasons.
   * This action is irreversible and should only be performed under specific conditions.
   *
   * @param metadataId - The ID of the Master Metadata to burn.
   * @param signer - The signer that will sign and execute the transaction.
   * @returns A promise that resolves to a reference to the deleted Master Metadata
   * object, if successful.
   */
  async burnMasterMetadata(
    metadataId: string,
    signer: Signer
  ): Promise<SuiObjectRef | undefined> {
    // Get the Master Metadata type
    const metadataType = await this.getMetadataType(metadataId);

    if (!metadataType) {
      throw new Error("Couldn't get Master Metadata type");
    }

    // Create a transaction block
    const txb = new TransactionBlock();

    // Call the smart contract function to burn a Master Metadata object
    txb.moveCall({
      target: `${PACKAGE_ID}::master::burn_metadata`,
      arguments: [txb.object(ADMIN_CAP), txb.object(metadataId)],
      typeArguments: [metadataType!],
    });

    // Sign and execute the transaction as the admin
    const res = await executeTransaction({ txb, signer });

    if (!res.effects?.deleted) {
      throw new Error(
        "No deleted objects were found in the SuiTransactionBlockResponse."
      );
    }

    // Find the deleted object in the response
    let deletedObject = res.effects.deleted.find(
      (deletedObject) => deletedObject.objectId === metadataId
    );

    if (!deletedObject) {
      throw new Error("Master Metadata object could not be burned.");
    }

    console.log("Metadata burned successfully:", deletedObject);

    return deletedObject;
  }

  /**
   * Syncs the title of a Master object with its corresponding Metadata title.
   *
   * @param masterId - The ID of the Master whose title is to be synced.
   * @param metadataId - The ID of the Metadata from which to sync the title.
   * @param signer - The signer that will sign and execute the transaction.
   * @returns A promise that resolves with the updated Master object.
   */
  async syncMasterTitle(
    masterId: string,
    metadataId: string,
    signer: Signer
  ): Promise<Master> {
    const txb = new TransactionBlock();
    const masterType = await this.getMasterType(masterId);

    if (!masterType) {
      throw new Error("Couldn't get Master type");
    }

    txb.moveCall({
      target: `${PACKAGE_ID}::master::sync_title`,
      arguments: [txb.object(masterId), txb.object(metadataId)],
      typeArguments: [masterType],
    });

    // Sign and execute the transaction
    const res = await executeTransaction({ txb, signer });

    // Check if the profile was updated successfully
    let updatedMaster = res.objectChanges!.find(
      (e) => e.type == "mutated" && e.objectType.includes("Master")
    );

    if (!updatedMaster || updatedMaster.type !== "mutated") {
      throw new Error("Master update failed.");
    }

    return await this.getMasterById(masterId);
  }

  /**
   * Syncs the image URL of a Master object with its corresponding Metadata image URL.
   *
   * @param masterId - The ID of the Master whose image URL is to be synced.
   * @param metadataId - The ID of the Metadata from which to sync the image URL.
   * @param signer - The signer that will sign and execute the transaction.
   * @returns A promise that resolves with the updated Master object.
   */
  async syncMasterImageUrl(
    masterId: string,
    metadataId: string,
    signer: Signer
  ): Promise<Master> {
    const txb = new TransactionBlock();
    const masterType = await this.getMasterType(masterId);

    if (!masterType) {
      throw new Error("Couldn't get Master type");
    }

    txb.moveCall({
      target: `${PACKAGE_ID}::master::sync_image_url`,
      arguments: [txb.object(masterId), txb.object(metadataId)],
      typeArguments: [masterType],
    });

    // Sign and execute the transaction
    const res = await executeTransaction({ txb, signer });

    // Check if the profile was updated successfully
    let updatedMaster = res.objectChanges!.find(
      (e) => e.type == "mutated" && e.objectType.includes("Master")
    );

    if (!updatedMaster || updatedMaster.type !== "mutated") {
      throw new Error("Master update failed.");
    }

    return await this.getMasterById(masterId);
  }

  /**
   * Syncs the media URL of a Master object with its corresponding Metadata media URL.
   *
   * @param masterId - The ID of the Master whose media URL is to be synced.
   * @param metadataId - The ID of the Metadata from which to sync the media URL.
   * @param signer - The signer that will sign and execute the transaction.
   * @returns A promise that resolves with the updated Master object.
   */
  async syncMasterMediaUrl(
    masterId: string,
    metadataId: string,
    signer: Signer
  ): Promise<Master> {
    const txb = new TransactionBlock();
    const masterType = await this.getMasterType(masterId);

    if (!masterType) {
      throw new Error("Couldn't get Master type");
    }

    txb.moveCall({
      target: `${PACKAGE_ID}::master::sync_media_url`,
      arguments: [txb.object(masterId), txb.object(metadataId)],
      typeArguments: [masterType],
    });

    // Sign and execute the transaction
    const res = await executeTransaction({ txb, signer });

    // Check if the profile was updated successfully
    let updatedMaster = res.objectChanges!.find(
      (e) => e.type == "mutated" && e.objectType.includes("Master")
    );

    if (!updatedMaster || updatedMaster.type !== "mutated") {
      throw new Error("Master update failed.");
    }

    return await this.getMasterById(masterId);
  }

  /**
   * Helper function to determine the type of a Master (Video or Audio).
   *
   * @param masterId - The ID of the Master object.
   * @returns The type of the Master (e.g., 'Video' or 'Audio').
   */
  async getMasterType(masterId: string): Promise<string | null> {
    const masterRes = await suiClient.getObject({
      id: masterId,
      options: { showContent: true },
    });

    const content: any = masterRes.data?.content;
    return getMasterT(content.type);
  }

  /**
   * Helper function to determine the type of a Master (Video or Audio).
   *
   * @param masterId - The ID of the Master object.
   * @returns The type of the Master (e.g., 'Video' or 'Audio').
   */
  async getMetadataType(metadataId: string): Promise<string | null> {
    const masterRes = await suiClient.getObject({
      id: metadataId,
      options: { showContent: true },
    });

    const content: any = masterRes.data?.content;
    return getMasterMetadataT(content.type);
  }

  /**
   * Updates the title of a Metadata object.
   *
   * @param metadataId - The ID of the Metadata to update.
   * @param newTitle - The new title to set for the Metadata.
   * @param signer - The signer that will sign and execute the transaction.
   * @returns A promise that resolves with the updated Master Metadata object.
   */
  async updateMetadataTitle(
    metadataId: string,
    newTitle: string,
    signer: Signer
  ): Promise<MasterMetadata> {
    const txb = new TransactionBlock();
    const metadataType = await this.getMetadataType(metadataId);

    if (!metadataType) {
      throw new Error("Couldn't get Master Metadata type");
    }

    txb.moveCall({
      target: `${PACKAGE_ID}::master::set_title`,
      arguments: [txb.object(metadataId), txb.pure(newTitle)],
      typeArguments: [metadataType],
    });

    // Sign and execute the transaction
    const res = await executeTransaction({ txb, signer });

    // Check if the profile was updated successfully
    let updatedMeta = res.objectChanges!.find(
      (e) => e.type == "mutated" && e.objectType.includes("Metadata")
    );

    if (!updatedMeta || updatedMeta.type !== "mutated") {
      throw new Error("Master Metadata update failed.");
    }

    return await this.getMasterMetadataById(metadataId);
  }

  /**
   * Updates the description of a Metadata object.
   *
   * @param metadataId - The ID of the Metadata to update.
   * @param newDescription - The new description to set for the Metadata.
   * @param signer - The signer that will sign and execute the transaction.
   * @returns A promise that resolves with the updated Master Metadata object.
   */
  async updateMetadataDescription(
    metadataId: string,
    newDescription: string,
    signer: Signer
  ): Promise<MasterMetadata> {
    const txb = new TransactionBlock();
    const metadataType = await this.getMetadataType(metadataId);

    if (!metadataType) {
      throw new Error("Couldn't get Master Metadata type");
    }

    txb.moveCall({
      target: `${PACKAGE_ID}::master::set_description`,
      arguments: [txb.object(metadataId), txb.pure(newDescription)],
      typeArguments: [metadataType],
    });

    // Sign and execute the transaction
    const res = await executeTransaction({ txb, signer });

    // Check if the profile was updated successfully
    let updatedMeta = res.objectChanges!.find(
      (e) => e.type == "mutated" && e.objectType.includes("Metadata")
    );

    if (!updatedMeta || updatedMeta.type !== "mutated") {
      throw new Error("Master Metadata update failed.");
    }

    return await this.getMasterMetadataById(metadataId);
  }

  /**
   * Updates the image URL of a Metadata object.
   *
   * @param metadataId - The ID of the Metadata to update.
   * @param newImageUrl - The new image URL to set for the Metadata.
   * @param signer - The signer that will sign and execute the transaction.
   * @returns A promise that resolves with the updated Master Metadata object.
   */
  async updateMetadataImageUrl(
    metadataId: string,
    newImageUrl: string,
    signer: Signer
  ): Promise<MasterMetadata> {
    const txb = new TransactionBlock();
    const metadataType = await this.getMetadataType(metadataId);

    if (!metadataType) {
      throw new Error("Couldn't get Master Metadata type");
    }

    txb.moveCall({
      target: `${PACKAGE_ID}::master::set_image_url`,
      arguments: [txb.object(metadataId), txb.pure(newImageUrl)],
      typeArguments: [metadataType],
    });

    // Sign and execute the transaction
    const res = await executeTransaction({ txb, signer });

    // Check if the profile was updated successfully
    let updatedMeta = res.objectChanges!.find(
      (e) => e.type == "mutated" && e.objectType.includes("Metadata")
    );

    if (!updatedMeta || updatedMeta.type !== "mutated") {
      throw new Error("Master Metadata update failed.");
    }

    return await this.getMasterMetadataById(metadataId);
  }

  /**
   * Updates the media URL of a Metadata object.
   * This transaction requires the signer to have an AdminCap.
   *
   * @param metadataId - The ID of the Metadata to update.
   * @param newMediaUrl - The new media URL to set for the Metadata.
   * @param signer - The admin signer that will sign and execute the transaction.
   * @returns A promise that resolves with the updated Master Metadata object.
   */
  async updateMetadataMediaUrl(
    metadataId: string,
    newMediaUrl: string,
    signer: Signer
  ): Promise<MasterMetadata> {
    const txb = new TransactionBlock();
    const metadataType = await this.getMetadataType(metadataId);

    if (!metadataType) {
      throw new Error("Couldn't get Master Metadata type");
    }

    txb.moveCall({
      target: `${PACKAGE_ID}::master::set_media_url`,
      arguments: [
        txb.object(ADMIN_CAP),
        txb.object(metadataId),
        txb.pure(newMediaUrl),
      ],
      typeArguments: [metadataType],
    });

    // Sign and execute the transaction
    const res = await executeTransaction({ txb, signer });

    // Check if the profile was updated successfully
    let updatedMeta = res.objectChanges!.find(
      (e) => e.type == "mutated" && e.objectType.includes("Metadata")
    );

    if (!updatedMeta || updatedMeta.type !== "mutated") {
      throw new Error("Master Metadata update failed.");
    }

    return await this.getMasterMetadataById(metadataId);
  }

  /**
   * Updates the hashtags of a Metadata object.
   * This transaction requires the signer to have an AdminCap.
   *
   * @param metadataId - The ID of the Metadata to update.
   * @param newHashtags - An array of new hashtags to replace the existing ones.
   * @param signer - The admin signer that will sign and execute the transaction.
   * @returns A promise that resolves with the updated Master Metadata object.
   */
  async updateMetadataHashtags(
    metadataId: string,
    newHashtags: string[],
    signer: Signer
  ): Promise<MasterMetadata> {
    const txb = new TransactionBlock();
    const metadataType = await this.getMetadataType(metadataId);

    if (!metadataType) {
      throw new Error("Couldn't get Master Metadata type");
    }

    txb.moveCall({
      target: `${PACKAGE_ID}::master::set_hashtags`,
      arguments: [
        txb.object(ADMIN_CAP),
        txb.object(metadataId),
        txb.pure(newHashtags),
      ],
      typeArguments: [metadataType],
    });

    // Sign and execute the transaction
    const res = await executeTransaction({ txb, signer });

    // Check if the profile was updated successfully
    let updatedMeta = res.objectChanges!.find(
      (e) => e.type == "mutated" && e.objectType.includes("Metadata")
    );

    if (!updatedMeta || updatedMeta.type !== "mutated") {
      throw new Error("Master Metadata update failed.");
    }

    return await this.getMasterMetadataById(metadataId);
  }

  // Additional update functions can be implemented similarly, following the patterns shown above.
}
