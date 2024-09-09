// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// user id sample e06feae0-6853-11ef-bd59-3a70d1c0463b

import { ProfileModule } from "../../modules/ProfileModule";
import { writeFileSync } from "fs";
import { join } from "path";
import { getSigner } from "../../utils";
import { RECRD_PRIVATE_KEY } from "../../config";
import { v4 } from "uuid";

(async () => {
  try {
    const profileModule = new ProfileModule();

    // Dummy values for testing purposes
    const numberOfProfiles = 100;

    const uids: string[] = Array(numberOfProfiles)
      .fill("")
      .map(() => v4());
    // console.log("uids", uids);
    const usernames: string[] = Array(numberOfProfiles).fill("");
    // const usernames: string[] = Array(numberOfProfiles)
    //   .fill("")
    //   .map((u, i) => `anon_${uids[i]}`);

    const result = await profileModule.new(
      uids,
      usernames,
      getSigner(RECRD_PRIVATE_KEY)
    );

    // Write the profile IDs to a temp file for use in other scripts
    writeFileSync(
      join(__dirname, "..", "tempProfileId.txt"),
      result.profile.map((res) => res.objectId).join("\n")
    );

    console.log("Profile created successfully:", result);
  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
