// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// This is a core module that will handle capabilities and anything abstract 
/// related that will need to be used in other modules too. We separate the 
/// logic to make it easier to maintain and to avoid circular dependencies.
module recrd::core {

  // === Imports ===

  use sui::object::{Self, UID};
  use sui::tx_context::{Self, TxContext};
  use sui::transfer;

  // === Friends ===

  // === Errors ===

  // === Constants ===

  // === Structs ===

  // Define an admin capability for giving permission for certain actions.
  struct AdminCap has key, store {
    id: UID,
  }

  // One-time-function that runs when the contract is deployed.
  fun init(ctx: &mut TxContext) {
    // Create a new `AdminCap` object.
    let admin_cap = AdminCap {
      id: object::new(ctx)
    };

    // Transfer the admin capability to the publisher of the contract.
    transfer::public_transfer(admin_cap, tx_context::sender(ctx));
  }


  // === Admin Functions ===

  public fun admin_new_cap(_: &AdminCap, ctx: &mut TxContext): AdminCap {
    AdminCap {
      id: object::new(ctx)
    }
  }

  // === Test Only ===
  #[test_only]
  public fun mint_for_testing(ctx: &mut TxContext): AdminCap {
    AdminCap {
      id: object::new(ctx)
    }
  }

  #[test_only]
  public fun burn_for_testing(admin_cap: AdminCap) {
    let AdminCap { id } = admin_cap;
    object::delete(id);
  }

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
  }
}