// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";
import { readFileSync } from "fs";
import { join } from "path";
import { getSigner } from "../../utils";
import { RECRD_PRIVATE_KEY } from "../../config";

(async () => {
  try {
    const profileModule = new ProfileModule();
    
    // Get last created Profile ID from temp file
    const profileId = readFileSync(join(__dirname, '..', 'tempProfileId.txt'), { encoding: 'utf-8' });
    const signer = getSigner(RECRD_PRIVATE_KEY);

    // Example of updating a couple of profile fields
    await profileModule.updateProfile(profileId, "watchTime", 3600, signer);
    const updateRes = await profileModule.updateProfile(profileId, "videosWatched", 42, signer);
    console.log("Updated profile:", updateRes);
  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
