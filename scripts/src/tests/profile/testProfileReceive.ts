// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";
import { USER_PRIVATE_KEY } from "../../config";
import { getSigner, getSuiAddress } from "../../utils";

(async () => {
  try {
    const profileModule = new ProfileModule();
    
    // Dummy Profile ID 
    const profileId = "0x51a3f7d2dcc1507e27b1428eb95fd57697c10ed9985e045a638499dfecbc473f";
    const masterId = "0x13c837a57a48170569a1a1373a06cd87099d433ea3d577032b9091f620d62745";

    const res = await profileModule.receiveMaster(profileId, masterId, getSigner(USER_PRIVATE_KEY));

    console.log("Receive Master response:", res);
  } catch (error) {
    console.error("Failed to receive Master:", error);
  }
})();
