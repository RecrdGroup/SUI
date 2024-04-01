// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "./modules/ProfileModule";
import { ADMIN_CAP, USER_PRIVATE_KEY } from "./config";
import { getSuiAddress } from "./utils";

(async () => {
  try {
    const profileModule = new ProfileModule();
    
    // Dummy values for testing purposes
    const userId = "testUserId";
    const username = "testUsername";
    
    const result = await profileModule.createAndShareProfile(userId, username);
    console.log("Profile created successfully:", result);

    const profileId = result.objectId;

    // Authorize user to update profile
    const userAddress = getSuiAddress(USER_PRIVATE_KEY);
    await profileModule.authorizeUser(profileId, userAddress, 1);

    // Example of updating a couple of profile fields
    await profileModule.updateProfile(profileId, "watchTime", 3600);
    const updateRes = await profileModule.updateProfile(profileId, "videosWatched", 42);
    console.log("Updated profile:", updateRes);
  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
