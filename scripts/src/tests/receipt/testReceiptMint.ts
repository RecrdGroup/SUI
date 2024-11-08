// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { RECRD_PRIVATE_KEY, USER_PRIVATE_KEY } from "../../config";
import { ReceiptModule } from "../../modules/ReceiptModule";
import { ProfileModule } from "../../modules/ProfileModule";
import { readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { getSigner, getSuiAddress } from "../../utils";

(async () => {
  try {
    const receiptModule = new ReceiptModule();
    const profileModule = new ProfileModule();

    // Get last minted Master ID and profile from temp file
    const masterId = readFileSync(join(__dirname, "..", "tempMasterId.txt"), {
      encoding: "utf-8",
    });

    // Get the seller profile ID from temp file
    const sellerProfileId = readFileSync(
      join(__dirname, "..", "tempProfileId.txt"),
      {
        encoding: "utf-8",
      }
    );

    // Create a new Profile for the buyer
    const buyerProfileRes = await profileModule.new(
      "buyer12345",
      "buyer-chan",
      getSigner(RECRD_PRIVATE_KEY)
      // getSuiAddress(USER_PRIVATE_KEY)
    );

    // Write the buyer profile ID to a temp file
    writeFileSync(
      join(__dirname, "..", "tempBuyerProfileId.txt"),
      buyerProfileRes.profile?.[0]?.objectId
    );

    // Create a new Receipt
    const res = await receiptModule.newReceipt(
      masterId,
      buyerProfileRes.profile?.[0]?.objectId,
      sellerProfileId,
      getSigner(RECRD_PRIVATE_KEY)
    );
    console.log("Receipt created successfully:", res);
  } catch (error) {
    console.error("Failed to create Receipt:", error);
  }
})();
