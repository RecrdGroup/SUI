// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";

(async () => {
  try {
    const profileModule = new ProfileModule();
    
    // Dummy Profile ID 
    const profileId = "0xd49483a6c1b818c517c64c65b608f7c695e2f0a89244409d65407ecd7327e246";

    // Example of updating a couple of profile fields
    await profileModule.updateProfile(profileId, "watchTime", 3600);
    const updateRes = await profileModule.updateProfile(profileId, "videosWatched", 42);
    console.log("Updated profile:", updateRes);
  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
