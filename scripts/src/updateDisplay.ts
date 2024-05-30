// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { TransactionBlock } from "@mysten/sui.js/transactions";
import { executeTransaction, getDisplayObjects, getSigner } from "./utils";
import { SUI_FRAMEWORK_ADDRESS } from "@mysten/sui.js/utils";
import {
  MASTER_SOUND_TYPE,
  MASTER_VIDEO_TYPE,
  RECRD_PRIVATE_KEY,
  METADATA_SOUND_TYPE,
  METADATA_VIDEO_TYPE,
} from "./config";

const addField = async (
  txb: TransactionBlock,
  displayObj: string,
  type: string,
  fname: string,
  fvalue: string
) => {
  txb.moveCall({
    target: `${SUI_FRAMEWORK_ADDRESS}::display::add`,
    arguments: [txb.object(displayObj), txb.pure(fname), txb.pure(fvalue)],
    typeArguments: [type],
  });
};

const removeField = async (
  txb: TransactionBlock,
  displayObj: string,
  type: string,
  fname: string
) => {
  txb.moveCall({
    target: `${SUI_FRAMEWORK_ADDRESS}::display::remove`,
    arguments: [txb.object(displayObj), txb.pure(fname)],
    typeArguments: [type],
  });
};

const editField = async (
  txb: TransactionBlock,
  displayObj: string,
  type: string,
  fname: string,
  fvalue: string
) => {
  txb.moveCall({
    target: `${SUI_FRAMEWORK_ADDRESS}::display::edit`,
    arguments: [txb.object(displayObj), txb.pure(fname), txb.pure(fvalue)],
    typeArguments: [type],
  });
};

const bumpVersion = async (
  txb: TransactionBlock,
  displayObj: string,
  type: string
) => {
  txb.moveCall({
    target: `${SUI_FRAMEWORK_ADDRESS}::display::update_version`,
    arguments: [txb.object(displayObj)],
    typeArguments: [type],
  });
};

const updateDisplay = async () => {
  const displayObjs = await getDisplayObjects();
  console.log("Display objects:", displayObjs);
  const signer = getSigner(RECRD_PRIVATE_KEY);
  const txb = new TransactionBlock();

  // ------- Updating Master Sound Display -------
  // Removing capital case Name to replace with lower case name
  removeField(txb, displayObjs.masterSoundDisplay!, MASTER_SOUND_TYPE, "Name");
  addField(
    txb,
    displayObjs.masterSoundDisplay!,
    MASTER_SOUND_TYPE,
    "name",
    "{title}"
  );

  // Removing Image URL field to replace with image_url
  removeField(
    txb,
    displayObjs.masterSoundDisplay!,
    MASTER_SOUND_TYPE,
    "Image URL"
  );
  addField(
    txb,
    displayObjs.masterSoundDisplay!,
    MASTER_SOUND_TYPE,
    "image_url",
    "{image_url}"
  );

  // Add project_url and creator fields
  addField(
    txb,
    displayObjs.masterSoundDisplay!,
    MASTER_SOUND_TYPE,
    "project_url",
    "https://www.recrd.com/"
  );
  addField(
    txb,
    displayObjs.masterSoundDisplay!,
    MASTER_SOUND_TYPE,
    "creator",
    "RECRD"
  );

  // ------- Updating Master Video Display -------
  // Removing capital case Name to replace with lower case name
  removeField(txb, displayObjs.masterVideoDisplay!, MASTER_VIDEO_TYPE, "Name");
  addField(
    txb,
    displayObjs.masterVideoDisplay!,
    MASTER_VIDEO_TYPE,
    "name",
    "{title}"
  );

  // Removing Image URL field to replace with image_url
  removeField(
    txb,
    displayObjs.masterVideoDisplay!,
    MASTER_VIDEO_TYPE,
    "Image URL"
  );
  addField(
    txb,
    displayObjs.masterVideoDisplay!,
    MASTER_VIDEO_TYPE,
    "image_url",
    "{image_url}"
  );

  // Add project_url and creator fields
  addField(
    txb,
    displayObjs.masterVideoDisplay!,
    MASTER_VIDEO_TYPE,
    "project_url",
    "https://www.recrd.com/"
  );
  addField(
    txb,
    displayObjs.masterVideoDisplay!,
    MASTER_VIDEO_TYPE,
    "creator",
    "RECRD"
  );

  // ------- Updating Metadata Video Display -------
  // Removing Title to replace it with name
  removeField(
    txb,
    displayObjs.metadataVideoDisplay!,
    METADATA_VIDEO_TYPE,
    "Title"
  );
  addField(
    txb,
    displayObjs.metadataVideoDisplay!,
    METADATA_VIDEO_TYPE,
    "name",
    "{title}"
  );

  // Removing Image URL field to replace with image_url
  removeField(
    txb,
    displayObjs.metadataVideoDisplay!,
    METADATA_VIDEO_TYPE,
    "Image URL"
  );
  addField(
    txb,
    displayObjs.metadataVideoDisplay!,
    METADATA_VIDEO_TYPE,
    "image_url",
    "{image_url}"
  );

  // Add project_url and creator fields
  addField(
    txb,
    displayObjs.metadataVideoDisplay!,
    METADATA_VIDEO_TYPE,
    "project_url",
    "https://www.recrd.com/"
  );
  addField(
    txb,
    displayObjs.metadataVideoDisplay!,
    METADATA_VIDEO_TYPE,
    "creator",
    "RECRD"
  );

  // ------- Updating Metadata Sound Display -------
  removeField(
    txb,
    displayObjs.metadataSoundDisplay!,
    METADATA_SOUND_TYPE,
    "Title"
  );
  addField(
    txb,
    displayObjs.metadataSoundDisplay!,
    METADATA_SOUND_TYPE,
    "name",
    "{title}"
  );

  // Removing Image URL field to replace with image_url
  removeField(
    txb,
    displayObjs.metadataSoundDisplay!,
    METADATA_SOUND_TYPE,
    "Image URL"
  );
  addField(
    txb,
    displayObjs.metadataSoundDisplay!,
    METADATA_SOUND_TYPE,
    "image_url",
    "{image_url}"
  );

  // Add project_url and creator fields
  addField(
    txb,
    displayObjs.metadataSoundDisplay!,
    METADATA_SOUND_TYPE,
    "project_url",
    "https://www.recrd.com/"
  );
  addField(
    txb,
    displayObjs.metadataSoundDisplay!,
    METADATA_SOUND_TYPE,
    "creator",
    "RECRD"
  );

  // ------- Bumping the version of all display objects so explorers can update -------
  bumpVersion(txb, displayObjs.masterSoundDisplay!, MASTER_SOUND_TYPE);
  bumpVersion(txb, displayObjs.masterVideoDisplay!, MASTER_VIDEO_TYPE);
  bumpVersion(txb, displayObjs.metadataSoundDisplay!, METADATA_SOUND_TYPE);
  bumpVersion(txb, displayObjs.metadataVideoDisplay!, METADATA_VIDEO_TYPE);

  // ------- Submitting transaction -------
  try {
    const res = await executeTransaction({ txb, signer });
    if (res.effects?.status.status === "success") {
      console.log("Display updated successfully!");
    } else {
      console.log("Display update failed!");
      console.error(res.errors);
    }
  } catch (e) {
    console.error(e);
  }
};

updateDisplay();
