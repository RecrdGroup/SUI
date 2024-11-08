// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { MasterModule } from "../../modules/MasterModule";
import { readFileSync } from "fs";
import { join } from "path";

(async () => {
  try {
    const masterModule = new MasterModule();

    // Get last minted Master ID from temp file
    const masterId = readFileSync(
      join(__dirname, "..", "tempMasterMetadataId.txt"),
      { encoding: "utf-8" }
    );

    const result = await masterModule.getMasterMetadataById(masterId);
    console.log("Master metadata:", result);
  } catch (error) {
    console.error("Failed to find Master:", error);
  }
})();
