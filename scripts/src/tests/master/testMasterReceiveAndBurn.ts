// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { RECRD_PRIVATE_KEY } from "../../config";
import { MasterModule } from "../../modules/MasterModule";
import { ProfileModule } from "../../modules/ProfileModule";
import { readFileSync } from "fs";
import { join } from "path";
import { getSigner } from "../../utils";

(async () => {
  try {
    const masterModule = new MasterModule();
    const profileModule = new ProfileModule();

    // Get last created Profile ID from temp file
    const profileId = readFileSync(join(__dirname, "..", "tempProfileId.txt"), {
      encoding: "utf-8",
    });

    // Get last minted Master ID from temp file
    const masterId = readFileSync(join(__dirname, "..", "tempMasterId.txt"), {
      encoding: "utf-8",
    });

    const res = await profileModule.receiveMaster(
      profileId,
      masterId,
      getSigner(RECRD_PRIVATE_KEY)
    );

    // Burn Master
    await masterModule.burnMaster(masterId, getSigner(RECRD_PRIVATE_KEY));
  } catch (error) {
    console.error("Failed to burn Master:", error);
  }
})();
