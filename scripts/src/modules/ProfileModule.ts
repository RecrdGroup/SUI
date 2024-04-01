// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { SuiObjectChangeCreated } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { executeTransaction, getSigner } from "../utils";
import { PACKAGE_ID, ADMIN_CAP, RECRD_PRIVATE_KEY, suiClient } from "../config";
import { Profile, AuthorizationDynamicFieldContent } from "../interfaces";

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

export class ProfileModule {
  /// Create and share a profile
  async createAndShareProfile(adminCap: string, userId: string, username: string): Promise<SuiObjectChangeCreated> {
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
    const signer = getSigner(RECRD_PRIVATE_KEY);
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
  async updateProfile(profileId: string, updateType: ProfileUpdateType, newValue: number): Promise<Profile> {
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
    const signer = getSigner(RECRD_PRIVATE_KEY);
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
  async authorizeUser(profileId: string, user: string, accessLevel: number): Promise<Profile> {
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
    const signer = getSigner(RECRD_PRIVATE_KEY);
    const response = await executeTransaction({ txb, signer });

    // Return updated profile
    return this.getProfileById(profileId);
  }

  /// TODO: buy
  /// TODO: receive_master
  /// TODO: borrow_master
  /// TODO: return_master
}