// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { MasterModule, mintMasterParams } from "../../modules/MasterModule";
import { SALE_STATUS } from "../../config";
import { readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { getSigner } from "../../utils";
import { RECRD_PRIVATE_KEY } from "../../config";

(async () => {
  try {
    const masterModule = new MasterModule();

    // Get last created Profile ID from temp file
    const profileId = readFileSync(join(__dirname, "..", "tempProfileId.txt"), {
      encoding: "utf-8",
    });

    // Mint a Master
    const mintMasterParams: mintMasterParams = {
      type: "Video",
      title: "Test Video",
      description: "This is a test video",
      image_url: "https://example.com/image.jpg",
      media_url: "https://example.com/video.mp4",
      hashtags: ["test", "video"],
      creator_profile_id: profileId,
      royalty_percentage_bp: 1000,
      master_metadata_parent: "", // replace with metadata id
      master_metadata_origin: "", // replace with metadata id
      expressions: 0,
      revenue_total: 0,
      revenue_available: 0,
      revenue_paid: 0,
      revenue_pending: 0,
      sale_status: SALE_STATUS.RETAINED,
    };

    const result = await masterModule.mintMaster(
      mintMasterParams,
      getSigner(RECRD_PRIVATE_KEY)
    );

    // Write the Master & Metadata IDs to a temp file for use in other scripts
    writeFileSync(
      join(__dirname, "..", "tempMasterId.txt"),
      result.master?.objectId!
    );
    writeFileSync(
      join(__dirname, "..", "tempMasterMetadataId.txt"),
      result.metadata?.objectId!
    );

    console.log("Master minted successfully:", result);
  } catch (error) {
    console.error("Failed to mint Master:", error);
  }
})();
