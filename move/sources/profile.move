// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// All users on `RECRD app will have a `Profile` object (registered and anonymous).
/// The user `Profile` object will include user related metadata, such as:
/// - User ID (we are considering to hash this information)
/// - Username (for registered users).
/// - Other metadata for user (TODO: What other meta do we want to store on-chain for user profile?)
/// - DAW related fields:
/// -- Static field for total time watched in seconds.
/// -- 1-1 dynamic field for every video the user has watched (TODO: to be considered)
module recrd::profile {

  // === Imports ===

  use sui::tx_context::{TxContext};
  use sui::transfer;
  use sui::object::{Self, UID};
  use std::string::{String};

  // === Friends ===

  // === Errors ===
  const EInvalidWatchTime: u64 = 0;

  // === Constants ===

  // === Structs ===

  struct Profile has key, store {
    // unique id for the profile object
    id: UID,
    // user ID derived from RECRD app db
    user_id: String, // type pending to decide the hashing approach
    // username
    username: String,
    // total time the user has spent on watching videos
    watch_time: u64, // in seconds
  }

  // === Public Functions ===

  // Create a new `Profile` object and make it a shared object.
  public fun create_and_share(
    user_id: String,
    username: String,
    ctx: &mut TxContext,
  ) {
    transfer::public_share_object(
      Profile {
        id: object::new(ctx),
        user_id: user_id,
        username: username,
        watch_time: 0, // initial watch time is zero
      }
    );
  }

  // Update the `watch_time` field of the `Profile` object.
  public fun update_watch_time(
    self: &mut Profile,
    new_watch_time: u64,
  ) {
    // Make sure the watch_time is greater than the current watch_time.
    assert!(new_watch_time > self.watch_time, EInvalidWatchTime);

    self.watch_time = new_watch_time;
  }
}