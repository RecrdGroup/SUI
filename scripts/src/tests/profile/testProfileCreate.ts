// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";
import { writeFileSync } from "fs";
import { join } from "path";

(async () => {
  try {
    const profileModule = new ProfileModule();
    
    // Dummy values for testing purposes
    const userId = "ab12345";
    const username = "alina-chan";
    
    const result = await profileModule.createAndShareProfile(userId, username);

    // Write the profile ID to a temp file for use in other scripts
    writeFileSync(join(__dirname, '..', 'tempProfileId.txt'), result.objectId);

    console.log("Profile created successfully:", result);

  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
