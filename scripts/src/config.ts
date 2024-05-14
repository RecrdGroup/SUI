// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import path from "path";
import { SuiClient } from "@mysten/sui.js/client";
import { config } from "dotenv";

const envPath = path.resolve(__dirname, "../.env");

config({
  path: envPath,
});

// Load the environment variables
export const SUI_NETWORK = process.env.SUI_NETWORK!;
export const PACKAGE_ID = process.env.RECRD_PACKAGE_ID!;
export const ADMIN_CAP = process.env.CORE_ADMIN_CAP!;
export const PUBLISHER = process.env.MASTER_PUBLISHER!;
export const REGISTRY = process.env.REGISTRY!;
export const RECRD_PRIVATE_KEY = process.env.RECRD_PRIVATE_KEY!;
export const USER_PRIVATE_KEY = process.env.USER_PRIVATE_KEY!;

// Create a SuiClient instance.
export const suiClient = new SuiClient({
  url: SUI_NETWORK,
});

// Access level constants per contract
export const ACCESS = {
  DEFAULT_ACCESS: 100,
  BORROW_ACCESS: 110,
  UPDATE_ACCESS: 120,
  REMOVE_ACCESS: 150,
  ADMIN_ACCESS: 200,
};

// Sale status constants per contract
export const SALE_STATUS = {
  RETAINED: 1,
  ON_SALE: 2,
  SUSPENDED: 3,
  CLAIMED: 4,
};

export const VIDEO_TYPE = `${PACKAGE_ID}::master::Video`;
export const AUDIO_TYPE = `${PACKAGE_ID}::master::Audio`;
export const LOYALTY_FREE_URL =
  "https://images.pexels.com/photos/19987062/pexels-photo-19987062/free-photo-of-a-close-up-of-pink-flowers-in-a-field.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2";

const keys = Object.keys(process.env);
console.log("env contains PACKAGE_ID:", keys.includes("RECRD_PACKAGE_ID"));
console.log("env contains ADMIN_CAP:", keys.includes("CORE_ADMIN_CAP"));
console.log(
  "env contains RECRD_PRIVATE_KEY:",
  keys.includes("RECRD_PRIVATE_KEY")
);
console.log(
  "env contains USER_PRIVATE_KEY:",
  keys.includes("USER_PRIVATE_KEY")
);
console.log("-----------------------------------");

// In config.ts, after loading environment variables
if (!SUI_NETWORK || !PACKAGE_ID || !ADMIN_CAP || !RECRD_PRIVATE_KEY) {
  console.error(
    "Critical environment variable(s) missing. Please check your .env file."
  );
  process.exit(1); // Exits the process with a failure code
}
