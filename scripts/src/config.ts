import { config } from "dotenv";

config({});
export const SUI_NETWORK = process.env.SUI_NETWORK!;
export const ADMIN_ADDRESS = process.env.ADMIN_ADDRESS!;
export const ADMIN_PHRASE = process.env.ADMIN_PHRASE!;
export const PACKAGE_ADDRESS = process.env.PACKAGE_ADDRESS!;
export const ADMIN_CAP = process.env.ADMIN_CAP!;
export const PROFILE_MINT_TARGET: `${string}::${string}::${string}` = `${PACKAGE_ADDRESS}::profile::create_and_share`;
export const PROFILE_UPDATE_TARGET: `${string}::${string}::${string}` = `${PACKAGE_ADDRESS}::profile::update_watch_time`;
export const MASTER_MINT_TARGET: `${string}::${string}::${string}` = `${PACKAGE_ADDRESS}::master::admin_new`;
export const MASTER_BURN_TARGET: `${string}::${string}::${string}` = `${PACKAGE_ADDRESS}::master::admin_burn_master`;
export const MASTER_BURN_METADATA_TARGET: `${string}::${string}::${string}` = `${PACKAGE_ADDRESS}::master::admin_burn_metadata`;
export const VIDEO_TYPE = `${PACKAGE_ADDRESS}::master::Video`;
export const AUDIO_TYPE = `${PACKAGE_ADDRESS}::master::Audio`;
export const LOYALTY_FREE_URL =
  "https://images.pexels.com/photos/19987062/pexels-photo-19987062/free-photo-of-a-close-up-of-pink-flowers-in-a-field.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2";

// console.log everything in the process.env object
const keys = Object.keys(process.env);
console.log("env contains ADMIN_ADDRESS:", keys.includes("ADMIN_ADDRESS"));
console.log("env contains ADMIN_PHRASE:", keys.includes("ADMIN_PHRASE"));
