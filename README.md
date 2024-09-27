# Smart Contracts & Architecture

This repo contains the smart contracts and architecture for the Recrd <> Sui implementation. The modules allow for the creation of User Profiles, Masters, Metadata & Receipts for facilitating on-chain Master ownership and trading.

# Module structure

Has 4 modules; core, master, profile & receipt.

- recrd::core manages the AdminCaps needed for admin actions in other modules. It is also responsible for version controlling sensitive functions.
- recrd::master creates and manages Master<T> and Metadata<T>. Also establishes the creation of Publisher and Display.
  - A Display can also be initialized or updated via PTBs.
  - More about the Display standard can be found [here](https://docs.sui.io/standards/display) & a helpful PTB construction tool is located [here](https://sui-tools.vercel.app/ptb-generator?network=testnet&objectId=&package=0x2&module=display&function=new_with_fields).
- recrd::profile creates user profiles. Provides an authorization framework which offers precise control over RECRD user profiles and their application related assets.
- recrd::receipt creates receipts for purchases. It is responsible for the creation of receipts and the effects that a purchase has on chain.

## Pre-requisites

- Install the cli locally and set up your testnet environment as well as testnet account (with the ed25519 scheme) by following the instructions in [Sui docs](https://docs.sui.io/guides/developer/getting-started/sui-install)
- Make sure you are using an environment that's connected to the testnet & that you've picked an account that's funded with SUI.
- You can generate a mnemonic phrase through the Sui cli or from any supported Sui wallet Chrome Extension.

## Getting started

- Navigate in the scripts folder and run `./publish testnet`.
- This will populate / create a .env file that will be used by the script to interact with the deployed modules.
  - NOTE: The script will pick the first account that can be seen from the `sui client addresses` command and use it as the publisher / admin account.
  - NOTE: For some of the commands you will need to have a second account that will be used as the user account. For this purpose fill in the `USER_PRIVATE_KEY` variable in the .env file with the private key of another account.
- Now you can run the integration tests. Ssome commands require as inputs objects that other commands create so make sure that you first run any prerequisite commands to interact with the modules.

  - Available commands:

    - `npm run testProfileNew` to mint a profile. CAUTION: Need to edit based on contract version (V1, V2) -- see corresponding file for more details
    - `npm run testProfileBatchNew` to mint multiple profiles. CAUTION: Need to edit based on contract version (V1, V2) -- see corresponding file for more details
    - `npm run testProfileAuthorize` to authorize an address to have a prticular access over the profile.
      - Requires a profile to be created first.
    - `npm run testProfileBatchAuthorize` to authorize multiple addresses to have a prticular access over the profile.
      - Requires a profile to be created first.
    - `npm run testProfileBatchDelete` to batch delete multiple profiles.
      - Requires a profile to be created first.
    - `npm run testProfileDeauthorize` to deauthorize an address from accessing the profile entirely.
      - Requires a profile to be created first & an address to be authorized.
    - `npm run testProfileUpdate` to update a profile's metadata field.
      - Requires a profile to be created first.
    - `npm run testProfileReceive` to receive a master from a profile.
      - Requires a profile to be created first & a master to be minted.
    - `npm run testMasterMint` to mint a master.
      - Requires a profile to be created first.
    - `npm run testMasterReceiveAndBurn` to receive a master and burn it.
      - Requires a profile to be created first & a master to be minted.
    - `npm run testGetMaster` to query the current state of a Master's fields.
      - Requires a master to be minted first under a profile.
    - `npm run testGetMasterMetadata` to query the current state of a Master's Metadata fields.
      - Requires a master to be minted first under a profile.
    - `npm run testMasterMetadataBurn` to burn a Master's Metadata shared object.
      - Requires a master to be minted first under a profile.
    - `npm run testReceiptMint` to mint a receipt.
      - Requires a master to be minted first under a profile.
    - `npm run testMasterBuy` to buy a master provided that the user has paid for it and received a receipt beforehand.
      - Requires a profile, a master on sale & a receipt.
    - `npm run testMasterSetOnSale` to update a master's sale_status field to ON_SALE.
      - User action.
      - Requires a master to be minted first under a profile.
    - `npm run testMasterRetain` to update a master's sale_status field to RETAINED.
      - User action. This is the unlist action.
      - Requires a master to be minted first under a profile.
    - `npm run testMasterSuspend` to update a master's sale_status field to SUSPENDED.
      - Admin action.
      - Requires a master to be minted first under a profile.
    - `npm run testMasterUnsuspend` to update a master's sale_status field to RETAINED.
      - Admin action.
      - Requires a master to be minted first under a profile and be suspended.
    - `npm run testMetadataSetTitleAndSync` to set a title for a Metadata object and sync it with the master.
      - Requires a master to be minted first under a profile.
    - `npm run testProfileBatchCombo` to test a realistic mainnet combination scenario of profile creations and user authorizations. Edit the file to configure the number of profiles and authorizations.
    - `npm run testIdentityDelete` to delete a user's identity.
      - Requires a profile to be created first.

  - To check transaction outputs in detail you can visit an explorer such as [Sui Explorer](https://suiexplorer.com/?network=testnet) and paste the digest in the search bar, which is printed by each script command, to see the full transaction effects.
