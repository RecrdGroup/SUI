# Initial Smart Contract - Playground

This is a simple version of the smart contract that will be used in the final project. It is a simple contract that allows for the creation of a Masters, Metadata & Profiles.

# Module structure

Has 3 modules; core, master and profile.

- recrd::core creates the AdminCap needed for admin actions in other modules.
- recrd::profile creates and shares a user profile, and updates the watch time of a user.
- recrd::master creates Master<T> and Metadata<T>. Includes burn functions for both. Also shows how to create publisher and display.

## Pre-requisites

- Install the cli locally and set up your testnet environment as well as testnet account (with the ed25519 scheme) by following the instructions in [Sui docs](https://docs.sui.io/guides/developer/getting-started/sui-install)
- Make sure you are using an environment that's connected to the testnet & that you've picked an account that's funded with SUI.
- You can generate a mnemonic phrase through the Sui cli or from any supported Sui wallet Chrome Extension.

## Getting started

- Export the following variables in your terminal:
  - `export ADMIN_ADDRESS="Your address starting with 0x.."`
  - `export ADMIN_PHRASE="Your seed phrase (12 words)"`
- Navigate in the scripts folder and run `./publish testnet`.
- This will populate / create a .env file that will be used by the script to interact with the deployed modules.
- Now you can edit the index.ts file (some commands require as inputs objects that other commands create) and run the corresponding commands to interact with the modules.
  - Available commands:
    - `npm run start mintProfile` to mint a profile.
    - `npm run start updateProfile` to update a profile.
    - `npm run start mintMaster` to mint a master.
    - `npm run start burnMaster` to burn a master.
    - `npm run start burnMetadata` to burn metadata.
  - To check transaction outputs in detail you can visit an explorer such as [Sui Explorer](https://suiexplorer.com/?network=testnet) and paste the digest in the search bar, which is printed by each script command, to see the full transaction effects.
