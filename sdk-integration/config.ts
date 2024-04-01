// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { SuiClient } from "@mysten/sui.js/client";
import { config } from "dotenv";

config({});

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

// console.log everything in the process.env object
const keys = Object.keys(process.env);
console.log("env contains PACKAGE_ID:", keys.includes("RECRD_PACKAGE_ID"));
console.log("env contains ADMIN_CAP:", keys.includes("CORE_ADMIN_CAP"));
console.log("env contains RECRD_PRIVATE_KEY:", keys.includes("RECRD_PRIVATE_KEY"));
console.log("env contains USER_PRIVATE_KEY:", keys.includes("USER_PRIVATE_KEY"));
console.log('-----------------------------------')