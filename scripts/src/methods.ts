import { SuiClient } from "@mysten/sui.js/client";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { SUI_FRAMEWORK_ADDRESS } from "@mysten/sui.js/utils";
import {
  ADMIN_ADDRESS,
  ADMIN_CAP,
  ADMIN_PHRASE,
  LOYALTY_FREE_URL,
  MASTER_BURN_METADATA_TARGET,
  MASTER_BURN_TARGET,
  MASTER_MINT_TARGET,
  PROFILE_MINT_TARGET,
  PROFILE_UPDATE_TARGET,
  SUI_NETWORK,
  VIDEO_TYPE,
} from "./config";

console.log("Connecting to SUI network: ", SUI_NETWORK);

const client = new SuiClient({ url: SUI_NETWORK });
const signer = Ed25519Keypair.deriveKeypair(ADMIN_PHRASE);

const execute = async ({ txb }: { txb: TransactionBlock }) => {
  return client.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    signer,
    requestType: "WaitForLocalExecution",
    options: {
      showEffects: true,
    },
  });
};

// === Profile Operations ===
const mintProfile = async () => {
  const txb = new TransactionBlock();
  txb.moveCall({
    target: PROFILE_MINT_TARGET,
    arguments: [txb.pure("1d2f3c"), txb.pure("Test User")],
  });
  const result = await execute({ txb });
  console.log(
    "Profile minted: ",
    result.effects?.created?.[0].reference.objectId
  );
  console.log("Digest: ", result.digest);
};

const updateProfile = async (profile: string, newWatchTime: number) => {
  const txb = new TransactionBlock();
  txb.moveCall({
    target: PROFILE_UPDATE_TARGET,
    arguments: [txb.object(profile), txb.pure(newWatchTime)],
  });
  const result = await execute({ txb });
  console.log("Digest: ", result.digest);
};

// === Master Operations ===
const mintMaster = async () => {
  const txb = new TransactionBlock();
  const none = txb.moveCall({
    target: `0x1::option::none`,
    arguments: [],
    typeArguments: [`${SUI_FRAMEWORK_ADDRESS}::object::ID`],
  });
  let master = txb.moveCall({
    target: MASTER_MINT_TARGET,
    arguments: [
      txb.object(ADMIN_CAP),
      txb.pure("Floweressence", "string"),
      txb.pure(LOYALTY_FREE_URL, "string"),
      txb.pure("Flowers of Spring", "string"),
      txb.pure(["Flower", "Spring", "Nature"], "vector<string>"),
      txb.pure(ADMIN_ADDRESS),
      txb.pure(100, "u16"),
      none,
      none,
      txb.pure(true),
    ],
    typeArguments: [VIDEO_TYPE],
  });
  txb.transferObjects([master], ADMIN_ADDRESS);
  const result = await execute({ txb });
  console.log("Digest: ", result.digest);
};

const burnMaster = async (masterId: string) => {
  const txb = new TransactionBlock();
  txb.moveCall({
    target: MASTER_BURN_TARGET,
    arguments: [txb.object(ADMIN_CAP), txb.object(masterId)],
    typeArguments: [VIDEO_TYPE],
  });
  const result = await execute({ txb });
  console.log("Digest: ", result.digest);
};

const burnMetadata = async (metadataId: string) => {
  const txb = new TransactionBlock();
  txb.moveCall({
    target: MASTER_BURN_METADATA_TARGET,
    arguments: [txb.object(ADMIN_CAP), txb.object(metadataId)],
    typeArguments: [VIDEO_TYPE],
  });
  const result = await execute({ txb });
  console.log("Digest: ", result.digest);
};

export { mintProfile, updateProfile, mintMaster, burnMaster, burnMetadata };
