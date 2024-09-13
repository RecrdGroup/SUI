// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";
import { USER_PRIVATE_KEY, RECRD_PRIVATE_KEY } from "../../config";
import { getSuiAddress, getSigner } from "../../utils";
import { readFileSync } from "fs";
import { join } from "path";

(async () => {
  try {
    const profileModule = new ProfileModule();

    // Get last created Profile ID from temp file
    const profileIds = readFileSync(
      join(__dirname, "..", "tempProfileId.txt"),
      {
        encoding: "utf-8",
      }
    );

    const profileIdsArr = profileIds.split("\n");

    // Batch burn profiles user to update profile
    const profileRes = await profileModule.batchBurn(
      profileIdsArr,
      getSigner(RECRD_PRIVATE_KEY)
    );

    console.log("Burn status:", profileRes.effects?.status);
    console.log("Digest:", profileRes.digest);
  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
