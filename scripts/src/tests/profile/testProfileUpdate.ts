// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";
import { readFileSync } from "fs";
import { join } from "path";
import { getSigner, getSuiAddress } from "../../utils";
import { RECRD_PRIVATE_KEY } from "../../config";

(async () => {
  try {
    const profileModule = new ProfileModule();

    // Get last created Profile ID from temp file
    const profileId = readFileSync(join(__dirname, "..", "tempProfileId.txt"), {
      encoding: "utf-8",
    });
    const signer = getSigner(RECRD_PRIVATE_KEY);

    // Example of updating a couple of profile fields
    await profileModule.updateProfile(
      profileId,
      "username",
      "default",
      "",
      signer
    );

    // Update the level of access for an address
    const updateRes = await profileModule.updateProfile(
      profileId,
      "authorization",
      180,
      getSuiAddress(RECRD_PRIVATE_KEY),
      signer
    );
    console.log("Updated profile:", updateRes);
  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
