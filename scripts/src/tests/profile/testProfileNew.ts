// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";
import { writeFileSync } from "fs";
import { join } from "path";
import { getSigner, getSuiAddress } from "../../utils";
import { RECRD_PRIVATE_KEY, USER_PRIVATE_KEY } from "../../config";

(async () => {
  try {
    const profileModule = new ProfileModule();

    // Dummy values for testing purposes
    const userId = "ab12345";
    const username = "alina-chan";
    const userAddress = getSuiAddress(USER_PRIVATE_KEY);

    const result = await profileModule.new(
      userId,
      username,
      userAddress,
      getSigner(RECRD_PRIVATE_KEY)
    );

    // Write the profile ID to a temp file for use in other scripts
    writeFileSync(
      join(__dirname, "..", "tempProfileId.txt"),
      result.profile.objectId
    );

    // Write the identity ID to a temp file for use in other scripts
    writeFileSync(
      join(__dirname, "..", "tempIdentityId.txt"),
      result.identity.objectId
    );

    console.log("Profile created successfully:", result);
  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
