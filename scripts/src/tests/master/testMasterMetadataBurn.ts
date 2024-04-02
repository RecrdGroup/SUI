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

    // Get last minted Master ID from temp file
    // const masterMetadataId = readFileSync(join(__dirname, '..', 'tempMasterMetadataId.txt'), { encoding: 'utf-8' });
    const masterMetadataId = "0x4b48b2bea89c391dcfa7eb81869c75d13a168ec6c0b5621c63df412332c8df07";

    // Burn Master
    await masterModule.burnMasterMetadata(masterMetadataId, getSigner(RECRD_PRIVATE_KEY));

  } catch (error) {
    console.error("Failed to burn Master Metadata:", error);
  }
})();
