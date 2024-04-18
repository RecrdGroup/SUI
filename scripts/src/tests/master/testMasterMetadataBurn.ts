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
    const masterMetadataId = readFileSync(join(__dirname, '..', 'tempMasterMetadataId.txt'), { encoding: 'utf-8' });

    // Burn Master
    await masterModule.burnMasterMetadata(masterMetadataId, getSigner(RECRD_PRIVATE_KEY));

  } catch (error) {
    console.error("Failed to burn Master Metadata:", error);
  }
})();
