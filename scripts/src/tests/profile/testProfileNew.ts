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
    const userId = "e06feae0-6853-11ef-bd59-3a70d1c0463b";
    // NOTE: Can use actual username for testing purposes
    const username = "";
    // CAUTION: Need to comment uncomment the following based on contract version (V1 requires it, V2 doesn't)
    const userAddress = getSuiAddress(USER_PRIVATE_KEY);

    const result = await profileModule.new(
      userId,
      username,
      getSigner(RECRD_PRIVATE_KEY),
      // CAUTION: Need to comment uncomment the following based on contract version (V1 requires it, V2 doesn't)
      userAddress
    );

    // Write the profile ID to a temp file for use in other scripts
    writeFileSync(
      join(__dirname, "..", "tempProfileId.txt"),
      result.profile[0].objectId
    );

    // Write the identity ID to a temp file for use in other scripts
    writeFileSync(
      join(__dirname, "..", "tempIdentityId.txt"),
      result.identity[0].objectId
    );

    console.log("Profile created successfully:", result);
  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
