// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import {
  SuiObjectChangeCreated,
  SuiTransactionBlockResponse,
} from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { executeTransaction, getMasterT } from "../utils";
import { PACKAGE_ID, ADMIN_CAP, suiClient } from "../config";
import { Profile, AuthorizationDynamicFieldContent } from "../interfaces";
import { Signer } from "@mysten/sui.js/cryptography";

// Contract supported functions for updating profile fields
const PROFILE_UPDATE_FUNCTIONS = {
  userId: "update_user_id",
  username: "update_username",
  watchTime: "update_watch_time",
  videosWatched: "update_videos_watched",
  advertsWatched: "update_adverts_watched",
  numberOfFollowers: "update_number_of_followers",
  numberOfFollowing: "update_number_of_following",
  adRevenue: "update_ad_revenue",
  commissionRevenue: "update_commission_revenue",
  authorization: "update_authorization",
};

type ProfileUpdateType = keyof typeof PROFILE_UPDATE_FUNCTIONS;

// Define a mapping of error codes to custom error messages
const errorCodeMessages = {
  "1": "Sender is not authorized to access the Profile",
  "2": "The object being received is not of the expected type.",
};

export class ProfileModule {
  /// Create and share a profile
  async new(
    userId: string | string[],
    username: string | string[],
    // userAddress: string | string[],
    signer: Signer
  ): Promise<{
    profile: SuiObjectChangeCreated[];
    // identity: SuiObjectChangeCreated[];
  }> {
    // If we are given an array for multiple users, we batch them.
    // But first we make sure the arrays are of the same length
    const isUserIdArray = Array.isArray(userId);
    const isUsernameArray = Array.isArray(username);
    // const isUserAddressArray = Array.isArray(userAddress);
    if (
      isUserIdArray &&
      isUsernameArray
      // && isUserAddressArray
    ) {
      if (
        userId.length !== username.length
        // || userId.length !== userAddress.length
      ) {
        throw new Error(
          "The arrays for userId, username, and userAddress must be of the same length."
        );
      }
    }
    // we also need to make sure that all are arrays if one of them is
    if (
      isUserIdArray ||
      isUsernameArray
      // || isUserAddressArray
    ) {
      if (
        !isUserIdArray ||
        !isUsernameArray
        //  || !isUserAddressArray
      ) {
        throw new Error(
          "If one of userId, username, and userAddress are provided as arrays, all must be arrays."
        );
      }
    }
    // Create a transaction block
    const txb = new TransactionBlock();

    for (let i = 0; i < (isUserIdArray ? userId.length : 1); i++) {
      // Call the smart contract function to create a profile and the user identity
      txb.moveCall({
        target: `${PACKAGE_ID}::profile::new`,
        arguments: [
          txb.object(ADMIN_CAP),
          txb.pure(isUserIdArray ? userId[i] : userId),
          txb.pure(isUsernameArray ? username[i] : username),
          // txb.pure(isUserAddressArray ? userAddress[i] : userAddress),
        ],
      });
    }

    // Sign and execute the transaction as RECRD
    const response = await executeTransaction({ txb, signer });

    // Check if the profile was created
    if (!response.effects?.created?.length) {
      throw new Error(
        "Profile creation failed or did not return expected result."
      );
    }

    const profileRes = response.objectChanges?.filter((object) => {
      return (
        object.type === "created" &&
        object.objectType.startsWith(`${PACKAGE_ID}::profile::Profile`)
      );
    }) as SuiObjectChangeCreated[] & {
      owner: {
        Shared: {
          /** The version at which the object became shared */
          initial_shared_version: string;
        };
      };
    };

    // const identityRes = response.objectChanges?.filter((object) => {
    //   return (
    //     object.type === "created" &&
    //     object.objectType.startsWith(`${PACKAGE_ID}::identity::Identity`)
    //   );
    // }) as SuiObjectChangeCreated[];

    return {
      profile: profileRes,
      // identity: identityRes,
    };
  }

  /// Update profile based on a specific field
  async updateProfile(
    profileId: string,
    updateType: ProfileUpdateType,
    newValue: string | number,
    addr: string,
    signer: Signer
  ): Promise<Profile> {
    // Create a transaction block
    const txb = new TransactionBlock();

    const updateFunctionName = PROFILE_UPDATE_FUNCTIONS[updateType];

    if (!updateFunctionName) {
      throw new Error("Invalid update type specified.");
    }

    // Construct the transaction call based on the update type
    if (updateType == "userId") {
      txb.moveCall({
        target: `${PACKAGE_ID}::profile::${updateFunctionName}`,
        arguments: [
          txb.object(ADMIN_CAP),
          txb.object(profileId),
          txb.pure(newValue, "string"),
        ],
      });
    } else if (updateType == "username") {
      txb.moveCall({
        target: `${PACKAGE_ID}::profile::${updateFunctionName}`,
        arguments: [txb.object(profileId), txb.pure(newValue, "string")],
      });
    } else if (updateType == "authorization") {
      txb.moveCall({
        target: `${PACKAGE_ID}::profile::${updateFunctionName}`,
        arguments: [
          txb.object(ADMIN_CAP),
          txb.object(profileId),
          txb.pure(addr),
          txb.pure(newValue),
        ],
      });
    } else {
      txb.moveCall({
        target: `${PACKAGE_ID}::profile::${updateFunctionName}`,
        arguments: [txb.object(profileId), txb.pure(newValue)],
      });
    }

    // Sign and execute the transaction
    const response = await executeTransaction({ txb, signer });

    // Check if the profile was updated successfully
    let updatedProfile = response.objectChanges!.find(
      (e) => e.type == "mutated" && e.objectType.includes("Profile")
    );

    if (!updatedProfile || updatedProfile.type !== "mutated") {
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
      options: { showContent: true },
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
        async ({ objectId }) => {
          const objectResponse = await suiClient.getObject({
            id: objectId,
            options: { showContent: true },
          });

          const parsedData = objectResponse.data
            ?.content as AuthorizationDynamicFieldContent;
          if (parsedData.dataType === "moveObject" && parsedData.fields) {
            return {
              address: parsedData.fields.name,
              level: parsedData.fields.value,
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
      });
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
    };
  }

  /// Authorize a user to access a profile with level of access within [0, 250]
  async authorizeUser(
    profileId: string | string[],
    user: string | string[],
    accessLevel: number | number[],
    signer: Signer
  ): Promise<boolean> {
    // First we make sure the arrays are of the same length
    const isProfileIdArray = Array.isArray(profileId);
    const isUserArray = Array.isArray(user);
    const isAccessLevelArray = Array.isArray(accessLevel);

    if (isProfileIdArray && isUserArray && isAccessLevelArray) {
      if (
        profileId.length !== user.length ||
        profileId.length !== accessLevel.length
      ) {
        throw new Error(
          "The arrays for profileId, user, and accessLevel must be of the same length."
        );
      }
    }
    // we also need to make sure that all are arrays if one of them is
    if (isProfileIdArray || isUserArray || isAccessLevelArray) {
      if (!isProfileIdArray || !isUserArray || !isAccessLevelArray) {
        throw new Error(
          "If one of profileId, user, and accessLevel are provided as arrays, all must be arrays."
        );
      }
    }

    // Create a transaction block
    const txb = new TransactionBlock();

    for (let i = 0; i < (isProfileIdArray ? profileId.length : 1); i++) {
      // If we are given an array for multiple profiles, we batch them.
      // Call the smart contract function to authorize a user

      const curAccessLevel = isAccessLevelArray ? accessLevel[i] : accessLevel;
      if (curAccessLevel < 0 || curAccessLevel > 250) {
        throw new Error("Invalid access level specified.");
      }
      txb.moveCall({
        target: `${PACKAGE_ID}::profile::authorize`,
        arguments: [
          txb.object(ADMIN_CAP),
          txb.object(isProfileIdArray ? profileId[i] : profileId),
          txb.pure(isUserArray ? user[i] : user),
          txb.pure(curAccessLevel),
        ],
      });
    }

    // Sign and execute the transaction
    const response = await executeTransaction({ txb, signer });

    if (response.effects?.status?.status === "failure") {
      console.error(
        "Error in authorizing user: ",
        response.effects.status.error
      );
    }

    // Return updated profile
    return response.effects?.status?.status === "success";
  }

  async batchCombo(
    userId: string[],
    username: string[],
    profileId: string[],
    authorizationAddress: string[],
    accessLevel: number[],
    signer: Signer
  ) {
    // Make sure userId, username, userAddress are of the same length
    if (userId.length !== username.length) {
      throw new Error(
        "The arrays for userId, username, and userAddress must be of the same length."
      );
    }
    // Make sure profileId, authorizationAddress and accessLevel are of the same length
    if (
      profileId.length !== authorizationAddress.length ||
      profileId.length !== accessLevel.length
    ) {
      throw new Error(
        "The arrays for profileId, authorizationAddress, and accessLevel must be of the same length."
      );
    }

    // Create a transaction block
    const txb = new TransactionBlock();

    for (let i = 0; i < userId.length; i++) {
      // Call the smart contract function to create a profile and the user identity
      txb.moveCall({
        target: `${PACKAGE_ID}::profile::new`,
        arguments: [
          txb.object(ADMIN_CAP),
          txb.pure(userId[i]),
          txb.pure(username[i]),
        ],
      });
    }

    for (let i = 0; i < profileId.length; i++) {
      // Call the smart contract function to authorize a user
      txb.moveCall({
        target: `${PACKAGE_ID}::profile::authorize`,
        arguments: [
          txb.object(ADMIN_CAP),
          txb.object(profileId[i]),
          txb.pure(authorizationAddress[i]),
          txb.pure(accessLevel[i]),
        ],
      });
    }

    // Sign and execute the transaction as RECRD
    const response = await executeTransaction({ txb, signer });

    // Check if the profiles were created
    if (!response.effects?.created?.length) {
      throw new Error("Batch combo failed or did not return expected result.");
    }

    return response;
  }

  /// Deauthorize a user from accessing a profile
  async deauthorizeUser(
    profileId: string,
    user: string,
    signer: Signer
  ): Promise<Profile> {
    // Retrieve the profile to get the authorizations
    let profile = await this.getProfileById(profileId);

    // Create a transaction block
    const txb = new TransactionBlock();

    // Call the smart contract function to deauthorize a user
    txb.moveCall({
      target: `${PACKAGE_ID}::profile::deauthorize`,
      arguments: [txb.object(ADMIN_CAP), txb.object(profileId), txb.pure(user)],
    });

    // Sign and execute the transaction
    const response = await executeTransaction({ txb, signer });

    // Retrieve the updated profile after deauthorization
    profile = await this.getProfileById(profileId);

    // Check if the user is removed from the authorizations table
    if (profile.authorizations.has(user)) {
      throw new Error("User was not deauthorized successfully.");
    }

    // Return updated profile
    return profile;
  }

  /// Buy Master from a profile and transfer to the buyer's profile
  async buyMaster(
    sellerProfile: string,
    masterId: string,
    buyerProfile: string,
    receiptId: string,
    signer: Signer
  ): Promise<SuiTransactionBlockResponse> {
    // Get the Master type
    const masterRes = await suiClient.getObject({
      id: masterId,
      options: { showContent: true },
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
      typeArguments: [masterType!],
    });

    // Sign and execute the transaction
    const response = await executeTransaction({ txb, signer });

    return response;
  }

  /// Receive Master from a profile if sender is authorized with REMOVE_ACCESS
  async receiveMaster(profileId: string, masterId: string, signer: Signer) {
    // Get the Master type
    const masterRes = await suiClient.getObject({
      id: masterId,
      options: { showContent: true },
    });

    const content: any = masterRes.data?.content;
    const masterType = getMasterT(content.type);

    // Create a transaction block
    const txb = new TransactionBlock();

    // Call the smart contract function to receive a Master object
    let master = txb.moveCall({
      target: `${PACKAGE_ID}::profile::admin_receive_master`,
      arguments: [
        txb.object(ADMIN_CAP),
        txb.object(profileId),
        txb.receivingRef({
          digest: masterRes.data?.digest!,
          objectId: masterId,
          version: masterRes.data?.version!,
        }),
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
    if (response.effects?.status?.status === "failure") {
      const errorMessage = response.effects.status.error;

      if (errorMessage?.includes("MoveAbort")) {
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
