// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module recrd::identity_test {
  // === Imports ===
  use std::string::utf8;
  use sui::test_scenario as ts;

  use recrd::core::{Self};
  use recrd::profile::{Self, Profile};
  use recrd::identity;
  
  // === Constants ===
  const ADMIN: address = @0xDECAF;
  const USER: address = @0xB00;
  const USERNAME: vector<u8> = b"username";
  const USER_ID: vector<u8> = b"user_id";

  #[test]
  public fun admin_mints_and_transfers_identity() {
    let mut scenario = ts::begin(ADMIN);
    let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

    // Create Profile for user
    ts::next_tx(&mut scenario, ADMIN);
    {
      profile::new(
          &admin_cap, 
          utf8(USER_ID), 
          utf8(USERNAME), 
          USER,
          ts::ctx(&mut scenario)
      );
    };
    
    ts::next_tx(&mut scenario, ADMIN);
    {
      let profile = ts::take_shared<Profile>(&scenario);
      let identity = identity::admin_new(&admin_cap, object::id(&profile), ts::ctx(&mut scenario));
      identity::admin_transfer(&admin_cap, identity, USER);
      ts::return_shared(profile);
    };

   
    core::burn_admincap(admin_cap);
    ts::end(scenario);
  }
}