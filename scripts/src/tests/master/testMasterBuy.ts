// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { PACKAGE_ID, USER_PRIVATE_KEY, suiClient } from "../../config";
import { ProfileModule } from "../../modules/ProfileModule";
import { readFileSync } from "fs";
import { join } from "path";
import { getSigner } from "../../utils";
import { useGetObjects } from "../../helpers/useGetObjects";

(async () => {
  const { getObjectsByType } = useGetObjects(suiClient);

  try {
    const profileModule = new ProfileModule();

    // Get the last profile ID from temp file as the seller
    const sellerProfileId = readFileSync(join(__dirname, '..', 'tempProfileId.txt'), { encoding: 'utf-8' });

    // Get the last created buyer profile ID from temp file
    // Run testReceiptMint.ts before this script to create a buyer profile
    const buyerProfileId = readFileSync(join(__dirname, '..', 'tempBuyerProfileId.txt'), { encoding: 'utf-8' });

    // Find a Receipt object from buyer profile
    const receiptObjects = await getObjectsByType(
      buyerProfileId,
      `${PACKAGE_ID}::receipt::Receipt`  
    );
    
    if (receiptObjects.length === 0) {
      throw new Error("No Receipt objects found for the buyer profile.");
    }
    
    console.log("Receipt objects:", receiptObjects);
    
    // Get the Master ID from the Receipt object
    const masterId = receiptObjects[0].content.fields.master_id;
    console.log("Master ID:", masterId);

    // Burn the Receipt
    const res = await profileModule.buyMaster(
      sellerProfileId,
      masterId,
      buyerProfileId,
      receiptObjects[0].objectId, 
      getSigner(USER_PRIVATE_KEY)
    );

    console.log("Master bought successfully:", res);
  } catch (error) {
    console.error("Failed to burn Receipt:", error);
  }
})();