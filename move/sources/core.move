// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
#[allow(unused_const)]
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
  const EWrongVersion: u64 = 0;

  // === Constants ===

  // Track the current version of the module.
  const VERSION: u64 = 1;

  // === Structs ===

  /// Define an admin capability for giving permission for certain actions.
  struct AdminCap has key, store {
    id: UID,
  }

  /// Global registry object to keep track of current package version. 
  struct Registry has key {
    id: UID,
    version: u64,
  }

  /// One-time-function that runs when the contract is deployed.
  fun init(ctx: &mut TxContext) {
    // Create the versioning registry object. 
    transfer::share_object(
      Registry {
        id: object::new(ctx),
        version: VERSION
      }
    );

    // Create a new `AdminCap` object.
    let admin_cap = AdminCap {
      id: object::new(ctx)
    };

    // Transfer the admin capability to the publisher of the contract.
    transfer::public_transfer(admin_cap, tx_context::sender(ctx));
  }


  // === Admin Functions ===

  /// Mints and returns a new `AdminCap` object. 
  /// Requires an AdminCap for authentication.
  public fun admin_new_cap(_: &AdminCap, ctx: &mut TxContext): AdminCap {
    AdminCap {
      id: object::new(ctx)
    }
  }

  /// Burns the `AdminCap` object.
  /// Requires two `AdminCap` objects to make sure that admin access is not lost.
  public fun admin_burn_cap(cap: AdminCap) {
    let AdminCap { id } = cap;
    object::delete(id);
  }

  /// Admin can update the registry's version.
  public fun admin_bump_registry_version(_: &AdminCap, registry: &mut Registry) {
    registry.version = VERSION;
  }

  /// Checks whether the registry's version matches the package version.
  public fun is_valid_version(registry: &Registry): bool {
    registry.version == VERSION
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