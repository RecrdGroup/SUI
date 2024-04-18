// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
#[allow(unused_const)]
/// This is a core module that will handle capabilities and anything abstract 
/// related that will need to be used in other modules too. We separate the 
/// logic to make it easier to maintain and to avoid circular dependencies.
module recrd::core {

  // === Imports ===
  use sui::package::{Publisher};

  // === Errors ===
  const EWrongVersion: u64 = 0;
  const EWrongPublisher: u64 = 1;

  // === Constants ===

  // Track the current version of the module.
  const VERSION: u64 = 1;

  // === Structs ===

  /// Define an admin capability for giving permission for certain actions.
  public struct AdminCap has key, store {
    id: UID,
  }

  /// Global registry object to keep track of current package version. 
  /// This allows or disables the issuance of new receipts.
  /// Allowed as long as Registry and VERSION are equal. 
  /// Not allowed if Registry has not been bumped to VERSION.
  public struct Registry has key {
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
    transfer::public_transfer(admin_cap, ctx.sender());
  }


  // === Admin Functions ===

  /// Mints and returns a new `AdminCap` object. 
  /// Requires Publisher for authentication.
  public fun new_admincap(publisher: &Publisher, ctx: &mut TxContext): AdminCap {
    // Make sure the publisher corresponds to the package that creates AdminCap.
    assert!(publisher.from_package<AdminCap>(), EWrongPublisher);

    AdminCap {
      id: object::new(ctx)
    }
  }

  /// Burns the `AdminCap` object.
  public fun burn_admincap(cap: AdminCap) {
    let AdminCap { id } = cap;
    id.delete();
  }

  /// Admin can update the registry's version.
  public fun bump_registry_version(registry: &mut Registry, _: &AdminCap) {
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
  public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
  }
}