// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";
import { RECRD_PRIVATE_KEY } from "../../config";
import { getSigner } from "../../utils";
import { readFileSync } from "fs";
import { join } from "path";
import { generate } from "../../helpers/mockAddressGenerator";

(async () => {
  try {
    const profileModule = new ProfileModule();

    // Dummy values for testing purposes
    const numberOfProfiles = 80;

    // Get last created Profile ID from temp file
    const profileIds = readFileSync(
      join(__dirname, "..", "tempProfileId.txt"),
      {
        encoding: "utf-8",
      }
    );

    const profileIdsArr = profileIds.split("\n");

    const userAddresses = generate(numberOfProfiles).map((u) => u.address);
    const accessLevels: number[] = Array(numberOfProfiles).fill(120);
    console.log("addresses", userAddresses);

    // Authorize user to update profile
    // const userAddress = getSuiAddress(RECRD_PRIVATE_KEY);
    const profileRes = await profileModule.authorizeUser(
      profileIdsArr,
      userAddresses,
      accessLevels,
      getSigner(RECRD_PRIVATE_KEY)
    );

    console.log("Updated profile:", profileRes);
  } catch (error) {
    console.error("Failed to authorize profiles:", error);
  }
})();
