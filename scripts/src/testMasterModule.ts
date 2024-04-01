// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { MasterModule } from "./modules/MasterModule";

(async () => {
  try {
    const masterModule = new MasterModule();

    const mintMasterParams = {
      type: "Video",
      title: "Test Video",
      description: "This is a test video",
      image_url: "https://example.com/image.jpg",
      media_url: "https://example.com/video.mp4",
      hashtags: ["test", "video"],
      creator_profile_id: "testProfileId",
      royalty_percentage_bp: 1000,
      sale_status: 1,
    };

    const result = await masterModule.mintMaster(mintMasterParams);
    console.log("Master minted successfully:", result);
  } catch (error) {
    console.error("Failed to mint Master:", error);
  }
})();