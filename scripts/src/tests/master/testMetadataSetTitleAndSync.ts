// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { RECRD_PRIVATE_KEY } from "../../config";
import { MasterModule } from "../../modules/MasterModule";
import { readFileSync } from "fs";
import { join } from "path";
import { getSigner } from "../../utils";

(async () => {
  try {
    const masterModule = new MasterModule();

    // Get last minted Master ID from temp file
    const masterId = readFileSync(join(__dirname, "..", "tempMasterId.txt"), {
      encoding: "utf-8",
    });

    // Get last minted Master Metadata ID from temp file
    const masterMetadataId = readFileSync(
      join(__dirname, "..", "tempMasterMetadataId.txt"),
      { encoding: "utf-8" }
    );

    // Get the last created Profile ID from temp file
    const profileId = readFileSync(join(__dirname, "..", "tempProfileId.txt"), {
      encoding: "utf-8",
    });

    // Update Master Metadata Title
    const metadataUpdateRes = await masterModule.updateMetadataTitle(
      profileId,
      masterId,
      masterMetadataId,
      "This is a new title",
      getSigner(RECRD_PRIVATE_KEY)
    );

    console.log(
      "Master Metadata Title updated successfully:",
      metadataUpdateRes
    );

    // Sync the changes of the Metadata to the Master
    const masterTitleSyncRes = await masterModule.syncMasterTitle(
      profileId,
      masterId,
      masterMetadataId,
      getSigner(RECRD_PRIVATE_KEY)
    );

    console.log(
      "Master Metadata Title synced successfully:",
      masterTitleSyncRes
    );
  } catch (error) {
    console.error("Failed to update & sync Master Metadata:", error);
  }
})();
