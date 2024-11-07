// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// user id sample e06feae0-6853-11ef-bd59-3a70d1c0463b

import { ProfileModule } from "../../modules/ProfileModule";
import { join } from "path";
import { getSigner } from "../../utils";
import { RECRD_PRIVATE_KEY } from "../../config";
import { v4 } from "uuid";
import { generate } from "../../helpers/mockAddressGenerator";
import { readFileSync } from "fs";

(async () => {
  try {
    const profileModule = new ProfileModule();

    // Dummy values for testing purposes
    const numberOfNewProfiles = 81;
    const numberOfAuthorizeProfiles = 19;

    const uids: string[] = Array(numberOfNewProfiles)
      .fill("")
      .map(() => v4());
    const usernames: string[] = Array(numberOfNewProfiles).fill("");
    // const usernames: string[] = Array(numberOfNewProfiles)
    //   .fill("")
    //   .map((u, i) => `anon_${uids[i]}`);
    // const userAddresses = generate(numberOfNewProfiles).map((u) => u.address);

    // Get last created Profile IDs from temp file.
    // Getting different profiles than the ones we just create to emulate mainnet txn.
    const profileIds = readFileSync(
      join(__dirname, "..", "tempProfileId.txt"),
      {
        encoding: "utf-8",
      }
    );

    const profileIdsArr = profileIds
      .split("\n")
      .slice(0, numberOfAuthorizeProfiles);
    const authorizationAddresses: string[] = generate(
      numberOfAuthorizeProfiles
    ).map((u) => u.address);
    const accessLevels: number[] = Array(numberOfAuthorizeProfiles).fill(120);

    const result = await profileModule.batchCombo(
      uids,
      usernames,
      profileIdsArr,
      authorizationAddresses,
      accessLevels,
      getSigner(RECRD_PRIVATE_KEY)
    );

    console.log("Batch executed successfully:", result.effects?.status);
    console.log("Digest", result.digest);
  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
