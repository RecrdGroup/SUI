// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { MasterModule, mintMasterParams } from "../../modules/MasterModule";
import { SALE_STATUS } from "../../config";

(async () => {
  try {
    const masterModule = new MasterModule();

    // Dummy Profile ID 
    const profileId = "0x9d49d0641d2e6d12700e13a36b1e61a8c170c5d3f6488093dcbaea192bf1354c";

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
      sale_status: SALE_STATUS.STALE,
    };

    const result = await masterModule.mintMaster(mintMasterParams);
    console.log("Master minted successfully:", result);
  } catch (error) {
    console.error("Failed to mint Master:", error);
  }
})();