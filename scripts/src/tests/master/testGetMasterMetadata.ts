// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { MasterModule } from "../../modules/MasterModule";

(async () => {
  try {
    const masterModule = new MasterModule();
    
    // Dummy Master ID
    const masterId = "0xb9d3a895e70cbdafc0103a7e785e60c35fe46a118c6e2cd9c4259be5dc7b99a7";
    
    const result = await masterModule.getMasterMetadataById(masterId);
    console.log("Master metadata:", result);

  } catch (error) {
    console.error("Failed to find Master:", error);
  }
})();
