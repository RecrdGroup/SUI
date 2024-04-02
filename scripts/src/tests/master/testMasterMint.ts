// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { MasterModule, mintMasterParams } from "../../modules/MasterModule";
import { ProfileModule } from "../../modules/ProfileModule";
import { SALE_STATUS } from "../../config";

(async () => {
  try {
    const masterModule = new MasterModule();
    const profileModule = new ProfileModule();

    // Mint a Profile object
    const userId = "testUserId";
    const username = "testUsername";
    const profileRes = await profileModule.createAndShareProfile(userId, username);

    const mintMasterParams: mintMasterParams = {
      type: "Video",
      title: "Test Video",
      description: "This is a test video",
      image_url: "https://example.com/image.jpg",
      media_url: "https://example.com/video.mp4",
      hashtags: ["test", "video"],
      creator_profile_id: profileRes.objectId,
      royalty_percentage_bp: 1000,
      sale_status: SALE_STATUS.STALE,
    };

    const result = await masterModule.mintMaster(mintMasterParams);
    console.log("Master minted successfully:", result);
  } catch (error) {
    console.error("Failed to mint Master:", error);
  }
})();