// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { SuiObjectChangeCreated, SuiTransactionBlockResponse } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { executeTransaction, getMasterT } from "../utils";
import { PACKAGE_ID, ADMIN_CAP, suiClient } from "../config";
import { Profile, AuthorizationDynamicFieldContent } from "../interfaces";
import { Signer } from "@mysten/sui.js/cryptography";

// Contract supported functions for updating profile fields
const PROFILE_UPDATE_FUNCTIONS = {
  watchTime: "update_watch_time",
  videosWatched: "update_videos_watched",
  advertsWatched: "update_adverts_watched",
  numberOfFollowers: "update_number_of_followers",
  numberOfFollowing: "update_number_of_following",
  adRevenue: "update_ad_revenue",
  commissionRevenue: "update_commission_revenue",
};

type ProfileUpdateType = keyof typeof PROFILE_UPDATE_FUNCTIONS;

// Define a mapping of error codes to custom error messages
const errorCodeMessages = {
  '1': "Sender is not authorized to access the Profile",
  '2': "The object being received is not of the expected type."
};

export class ProfileModule {
  /// Create and share a profile
  async createAndShareProfile(userId: string, username: string, signer: Signer): Promise<SuiObjectChangeCreated> {
    // Create a transaction block
    const txb = new TransactionBlock();

    // Call the smart contract function to create and share a profile
    txb.moveCall({
      target: `${PACKAGE_ID}::profile::create_and_share`,
      arguments: [
        txb.object(ADMIN_CAP),
        txb.pure(userId), 
        txb.pure(username)
      ],
    });

    // Sign and execute the transaction as RECRD 
    const response = await executeTransaction({ txb, signer });

    // Check if the profile was created
    if (!response.effects?.created?.length) {
      throw new Error("Profile creation failed or did not return expected result.");
    }

    return response.objectChanges?.find((object) => {
      return object.type === 'created' && object.objectType.startsWith(`${PACKAGE_ID}::profile::Profile`);
    }) as SuiObjectChangeCreated & {
      owner: {
        Shared: {
          /** The version at which the object became shared */
          initial_shared_version: string;
        };
      }
    };
  }

  /// Update profile based on a specific field
  async updateProfile(profileId: string, updateType: ProfileUpdateType, newValue: number, signer: Signer): Promise<Profile> {
    // Create a transaction block
    const txb = new TransactionBlock();

    const updateFunctionName = PROFILE_UPDATE_FUNCTIONS[updateType];

    if (!updateFunctionName) {
      throw new Error("Invalid update type specified.");
    }

    // Construct the transaction call based on the update type
    txb.moveCall({
      target: `${PACKAGE_ID}::profile::${updateFunctionName}`,
      arguments: [
        txb.object(ADMIN_CAP),
        txb.object(profileId),
        txb.pure(newValue),
      ],
    });

    // Sign and execute the transaction
    const response = await executeTransaction({ txb, signer });
    
    // Check if the profile was updated successfully
    let updatedProfile = response.objectChanges!.find(
      (e) => e.type == 'mutated' && e.objectType.includes('Profile'),
    );

    if (!updatedProfile || updatedProfile.type !== 'mutated') {
      throw new Error("Profile update failed.");
    }

    // Return the updated profile
    return this.getProfileById(profileId);
  }

  /// Query a profile by its ID and return Profile with all fields data
  async getProfileById(profileId: string): Promise<Profile> {
    // Retrieve the profile 
    const profile = await suiClient.getObject({
      id: profileId, 
      options: { showContent: true } 
    });

    const profileContent: any = profile.data?.content;

    // Initialize the authorizations as empty Map
    const authorizations = new Map<string, number>();

    // Check if there are any authorizations given for the profile
    if (profileContent.fields?.authorizations.fields.size > 0) {
      // Retrieve the dynamic fields for authorizations
      const { data: dynamicFieldsData } = await suiClient.getDynamicFields({
        parentId: profileContent?.fields?.authorizations.fields.id.id,
      });

      // Retrieve the content for each authorization dynamic field
      const authorizationPromises = dynamicFieldsData.map(
        async({objectId}) => {
          const objectResponse = await suiClient.getObject({
            id: objectId,
            options: { showContent: true },
          });

          const parsedData = objectResponse.data?.content as AuthorizationDynamicFieldContent;
          if (parsedData.dataType === 'moveObject' && parsedData.fields) {
            return {
              address: parsedData.fields.name,
              level: parsedData.fields.value
            };
          } else {
            console.error(`Object with id ${objectId} is not a moveObject`);
            return null;
          }
        }
      );
      
      // Wait for all authorizations to be resolved
      const authorizationData = await Promise.all(authorizationPromises);
      
      // Set the authorizations in the Map
      authorizationData.forEach((authorization) => {
        if (authorization) {
          authorizations.set(authorization.address, authorization.level);
        }
      }
      );
    }

    return {
      id: profileId,
      userId: profileContent.fields?.user_id,
      username: profileContent.fields?.username,
      authorizations: authorizations,
      watchTime: profileContent.fields?.watch_time,
      videosWatched: profileContent.fields?.videos_watched,
      advertsWatched: profileContent.fields?.adverts_watched,
      numberOfFollowers: profileContent.fields?.number_of_followers,
      numberOfFollowing: profileContent.fields?.number_of_followers,
      adRevenue: profileContent.fields?.ad_revenue,
      commissionRevenue: profileContent.fields?.commission_revenue,
    }
  }

  /// Authorize a user to access a profile with 
  /// 0 = BORROW_ACCESS or
  /// 1 = REMOVE_ACCESS
  async authorizeUser(profileId: string, user: string, accessLevel: number, signer: Signer): Promise<Profile> {
    if (accessLevel < 0 || accessLevel > 1) {
      throw new Error("Invalid access level specified.");
    }

    // Create a transaction block
    const txb = new TransactionBlock();

    // Call the smart contract function to authorize a user
    txb.moveCall({
      target: `${PACKAGE_ID}::profile::authorize`,
      arguments: [
        txb.object(ADMIN_CAP),
        txb.object(profileId),
        txb.pure(user),
        txb.pure(accessLevel),
      ],
    });

    // Sign and execute the transaction
    const response = await executeTransaction({ txb, signer });

    // Return updated profile
    return this.getProfileById(profileId);
  }

  /// Buy Master from a profile and transfer to the buyer's profile
  async buyMaster(sellerProfile: string, masterId: string, buyerProfile: string, receiptId: string, signer: Signer): Promise<SuiTransactionBlockResponse> {
    // Get the Master type
    const masterRes = await suiClient.getObject({ 
      id: masterId,
      options: { showContent: true }
    });

    const content: any = masterRes.data?.content;
    const masterType = getMasterT(content.type);

    // Create a transaction block
    const txb = new TransactionBlock();
    
    // Call the smart contract function to buy a Master object
    txb.moveCall({
      target: `${PACKAGE_ID}::profile::buy`,
      arguments: [
        txb.object(sellerProfile),
        txb.object(masterId),
        txb.object(buyerProfile),
        txb.object(receiptId),
      ],
      typeArguments:[masterType!]
    });

    // Sign and execute the transaction
    const response = await executeTransaction({ txb, signer });

    return response;
  }

  /// Receive Master from a profile if sender is authorized with REMOVE_ACCESS (1)
  async receiveMaster(profileId: string, masterId: string, signer: Signer) {
    // Get the Master type 
    const masterRes = await suiClient.getObject({ 
      id: masterId,
      options: { showContent: true }
    });

    const content: any = masterRes.data?.content;
    const masterType = getMasterT(content.type);

    // Create a transaction block
    const txb = new TransactionBlock();

    // Call the smart contract function to receive a Master object
    let master = txb.moveCall({
      target: `${PACKAGE_ID}::profile::receive_master`,
      arguments: [
        txb.object(profileId),
        txb.object(masterId),
      ],
      typeArguments: [masterType!],
    });

    // Get the Sui address of the signer
    const signerAddress = signer.getPublicKey().toSuiAddress();

    // Transfer the Master object to the signer
    txb.transferObjects([master], signerAddress);

    // Sign and execute the transaction
    const response = await executeTransaction({ txb, signer });
    
    // Check if the response indicates a MoveAbort failure
    if (response.effects?.status?.status === 'failure') {
      const errorMessage = response.effects.status.error;

      if (errorMessage?.includes('MoveAbort')) {
        // Iterate through the error codes and check if the error message matches one
        for (const [code, message] of Object.entries(errorCodeMessages)) {
          if (errorMessage.includes(`${code}) in command`)) {
            throw new Error(message);
          }
        }
      }
    }

    // Return the received Master object
    return response;
  }
}