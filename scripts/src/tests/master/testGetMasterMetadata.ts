// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { MasterModule } from "../../modules/MasterModule";

(async () => {
  try {
    const masterModule = new MasterModule();
    
    // Dummy Master ID
    const masterId = "0x7745efcc9ce06a7a6c2322f65e68764e39de31444b6f16c0152b440c83ebc005";
    
    const result = await masterModule.getMasterMetadataById(masterId);
    console.log("Master metadata:", result);

  } catch (error) {
    console.error("Failed to find Master:", error);
  }
})();
