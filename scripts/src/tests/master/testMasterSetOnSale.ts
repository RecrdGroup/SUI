// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { USER_PRIVATE_KEY } from "../../config";
import { MasterModule } from "../../modules/MasterModule";
import { readFileSync } from "fs";
import { join } from "path";
import { getSigner } from "../../utils";

(async () => {
  try {
    const masterModule = new MasterModule();

    // Get last created Profile ID from temp file
    const profileId = readFileSync(join(__dirname, "..", "tempProfileId.txt"), {
      encoding: "utf-8",
    });

    // Get last minted Master ID from temp file
    const masterId = readFileSync(join(__dirname, "..", "tempMasterId.txt"), {
      encoding: "utf-8",
    });

    // Listing a master for sale can only be performed by the user.
    const res = await masterModule.listMaster(
      profileId,
      masterId,
      getSigner(USER_PRIVATE_KEY)
    );
    console.log("Master status updated successfully:", res);
  } catch (error) {
    console.error("Failed to list Master for sale:", error);
  }
})();
