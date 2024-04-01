// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { MasterModule } from "../../modules/MasterModule";

(async () => {
  try {
    const masterModule = new MasterModule();
    
    // Dummy Master ID
    const masterId = "0x13c837a57a48170569a1a1373a06cd87099d433ea3d577032b9091f620d62745";
    
    const result = await masterModule.getMasterById(masterId);
    console.log("Master:", result);

  } catch (error) {
    console.error("Failed to find Master:", error);
  }
})();
