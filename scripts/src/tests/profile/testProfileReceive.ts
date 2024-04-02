// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";
import { USER_PRIVATE_KEY, RECRD_PRIVATE_KEY } from "../../config";
import { getSigner, getSuiAddress } from "../../utils";

(async () => {
  try {
    const profileModule = new ProfileModule();
    
    // Dummy Profile ID 
    const profileId = "0x9d49d0641d2e6d12700e13a36b1e61a8c170c5d3f6488093dcbaea192bf1354c";

    // Dummy Master ID
    const masterId = "0x5fced89bf2d35f399eaf9bd9f9718cccf1f0e4a01eaddad814ea6767c81014d0";

    const res = await profileModule.receiveMaster(profileId, masterId, getSigner(USER_PRIVATE_KEY));

    console.log("Receive Master response:", res);
  } catch (error) {
    console.error("Failed to receive Master:", error);
  }
})();
