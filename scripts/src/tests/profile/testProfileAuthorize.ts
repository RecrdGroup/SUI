// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";
import { USER_PRIVATE_KEY, ACCESS } from "../../config";
import { getSuiAddress } from "../../utils";

(async () => {
  try {
    const profileModule = new ProfileModule();
    
    // Dummy Profile ID 
    const profileId = "0x9d49d0641d2e6d12700e13a36b1e61a8c170c5d3f6488093dcbaea192bf1354c";
    
    // Authorize user to update profile
    const userAddress = getSuiAddress(USER_PRIVATE_KEY);
    const profileRes = await profileModule.authorizeUser(profileId, userAddress, ACCESS.REMOVE);

    console.log("Updated profile:", profileRes);
  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
