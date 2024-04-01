// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";
import { USER_PRIVATE_KEY } from "../../config";
import { getSuiAddress } from "../../utils";

(async () => {
  try {
    const profileModule = new ProfileModule();
    
    // Dummy Profile ID 
    const profileId = "0xa5cfc3c00e495b8270af85fc7e6e7ac1422ec3362d13ca0db52585526d234b14";
    
    // Authorize user to update profile
    const userAddress = getSuiAddress(USER_PRIVATE_KEY);
    const profileRes = await profileModule.authorizeUser(profileId, userAddress, 1);

    console.log("Updated profile:", profileRes);
  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
