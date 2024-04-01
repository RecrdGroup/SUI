// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { SuiClient } from "@mysten/sui.js/client";
import { config } from "dotenv";

config({});

// Load the environment variables
export const SUI_NETWORK = process.env.SUI_NETWORK!;
export const PACKAGE_ID = process.env.RECRD_PACKAGE_ID!;
export const ADMIN_CAP = process.env.CORE_ADMIN_CAP!;
export const PUBLISHER = process.env.MASTER_PUBLISHER!;
export const RECRD_PRIVATE_KEY = process.env.RECRD_PRIVATE_KEY!;
export const USER_PRIVATE_KEY = process.env.USER_PRIVATE_KEY!;

// Create a SuiClient instance.
const client = new SuiClient({
  url: SUI_NETWORK,
});

// Define moveCall targets for smart contracts
export const PROFILE_MINT_TARGET: `${string}::${string}::${string}` = `${PACKAGE_ID}::profile::create_and_share`;
export const PROFILE_UPDATE_TARGET: `${string}::${string}::${string}` = `${PACKAGE_ID}::profile::update_watch_time`;
export const MASTER_MINT_TARGET: `${string}::${string}::${string}` = `${PACKAGE_ID}::master::admin_new`;
export const MASTER_BURN_TARGET: `${string}::${string}::${string}` = `${PACKAGE_ID}::master::admin_burn_master`;
export const MASTER_BURN_METADATA_TARGET: `${string}::${string}::${string}` = `${PACKAGE_ID}::master::admin_burn_metadata`;
export const VIDEO_TYPE = `${PACKAGE_ID}::master::Video`;
export const AUDIO_TYPE = `${PACKAGE_ID}::master::Audio`;
export const LOYALTY_FREE_URL =
  "https://images.pexels.com/photos/19987062/pexels-photo-19987062/free-photo-of-a-close-up-of-pink-flowers-in-a-field.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2";

  const keys = Object.keys(process.env);
  console.log("env contains PACKAGE_ID:", keys.includes("RECRD_PACKAGE_ID"));
  console.log("env contains ADMIN_CAP:", keys.includes("CORE_ADMIN_CAP"));
  console.log("env contains RECRD_PRIVATE_KEY:", keys.includes("RECRD_PRIVATE_KEY"));
  console.log("env contains USER_PRIVATE_KEY:", keys.includes("USER_PRIVATE_KEY"));
  console.log('-----------------------------------')
