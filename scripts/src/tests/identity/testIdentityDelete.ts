// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { ProfileModule } from "../../modules/ProfileModule";
import { USER_PRIVATE_KEY, RECRD_PRIVATE_KEY } from "../../config";
import { getSuiAddress, getSigner } from "../../utils";
import { readFileSync } from "fs";
import { join } from "path";

(async () => {
  try {
    const profileModule = new ProfileModule();

    // Get last created Identity ID from temp file
    const identityId = readFileSync(
      join(__dirname, "..", "tempIdentityId.txt"),
      {
        encoding: "utf-8",
      }
    );

    console.log("Identity ID:", identityId);
    // Burn User's Identity
    const identiyBurnRes = await profileModule.deleteIdentity(
      identityId,
      getSigner(USER_PRIVATE_KEY)
    );

    console.log("Status:", identiyBurnRes.effects?.status);
    console.log("Digest:", identiyBurnRes.digest);
  } catch (error) {
    console.error("Failed to create profile:", error);
  }
})();
