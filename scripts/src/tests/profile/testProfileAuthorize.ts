// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";
import { USER_PRIVATE_KEY, REMOVE_ACCESS } from "../../config";
import { getSuiAddress } from "../../utils";

(async () => {
  try {
    const profileModule = new ProfileModule();
    
    // Dummy Profile ID 
    const profileId = "0x51a3f7d2dcc1507e27b1428eb95fd57697c10ed9985e045a638499dfecbc473f";
    
    // Authorize user to update profile
    const userAddress = getSuiAddress(USER_PRIVATE_KEY);
    const profileRes = await profileModule.authorizeUser(profileId, userAddress, REMOVE_ACCESS);

    console.log("Updated profile:", profileRes);
  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
