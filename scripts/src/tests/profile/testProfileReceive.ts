// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";
import { USER_PRIVATE_KEY } from "../../config";
import { getSigner } from "../../utils";
import { readFileSync } from "fs";
import { join } from "path";

(async () => {
  try {
    const profileModule = new ProfileModule();
    
    // Get last created Profile ID from temp file
    const profileId = readFileSync(join(__dirname, '..', 'tempProfileId.txt'), { encoding: 'utf-8' });

    // Get last minted Master ID from temp file
    const masterId = readFileSync(join(__dirname, '..', 'tempMasterId.txt'), { encoding: 'utf-8' });

    const res = await profileModule.receiveMaster(profileId, masterId, getSigner(USER_PRIVATE_KEY));

    console.log("Receive Master response:", res);
  } catch (error) {
    console.error("Failed to receive Master:", error);
  }
})();
