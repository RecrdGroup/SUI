// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";

(async () => {
  try {
    const profileModule = new ProfileModule();
    
    // Dummy values for testing purposes
    const userId = "ab12345";
    const username = "alina-chan";
    
    const result = await profileModule.createAndShareProfile(userId, username);
    console.log("Profile created successfully:", result);

  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
