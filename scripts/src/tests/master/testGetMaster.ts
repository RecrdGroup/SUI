// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { MasterModule } from "../../modules/MasterModule";

(async () => {
  try {
    const masterModule = new MasterModule();
    
    // Dummy Master ID
    const masterId = "0x8be70d76d4068fed6a64eac4465dfa4747ea897badfe5b721ab3e548bf24a2a5";
    
    const result = await masterModule.getMasterById(masterId);
    console.log("Master:", result);

  } catch (error) {
    console.error("Failed to find Master:", error);
  }
})();
