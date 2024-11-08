// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";
import { USER_PRIVATE_KEY, ACCESS, RECRD_PRIVATE_KEY } from "../../config";
import { getSuiAddress, getSigner } from "../../utils";
import { readFileSync } from "fs";
import { join } from "path";

(async () => {
  try {
    const profileModule = new ProfileModule();

    // Get last created Profile ID from temp file
    const profileId = readFileSync(join(__dirname, "..", "tempProfileId.txt"), {
      encoding: "utf-8",
    });

    // Authorize user to update profile
    const userAddress = getSuiAddress(RECRD_PRIVATE_KEY);
    const profileRes = await profileModule.authorizeUser(
      profileId,
      userAddress,
      ACCESS.REMOVE_ACCESS,
      getSigner(RECRD_PRIVATE_KEY)
    );

    console.log("Updated profile:", profileRes);
  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
