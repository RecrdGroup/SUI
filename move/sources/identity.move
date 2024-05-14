// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
module recrd::identity {
  use recrd::core::AdminCap;

  // === Custom Receivers ===
  use fun new as ID.new;

  // Profile identity for users to link their account to their Profile. 
  public struct Identity has key {
    id: UID,
    profile: ID,
  }

  // === Admin Functions ===

  /// Admin can send more Identities to users that have existing Profile. 
  public fun admin_new(_: &AdminCap, profile_id: ID, ctx: &mut TxContext): Identity {
    profile_id.new(ctx)
  }

  public fun admin_transfer(_: &AdminCap, self: Identity, addr: address) {
    self.transfer(addr);
  }

  // === Public Functions ===
  public fun burn(self: Identity) {
    let Identity { id, profile: _ } = self;
    id.delete();
  }

  // === Private Functions ===

  // Internal transfer function for `Identity`.
  public(package) fun transfer(self: Identity, addr: address) {
    transfer::transfer(self, addr);
  }

  /// Creates and returns a new Identity object. 
  public(package) fun new(profile_id: ID, ctx: &mut TxContext): Identity {
    Identity {
      id: object::new(ctx),
      profile: profile_id,
    }
  }

  #[test_only]
  public fun create_for_testing(profile_id: ID, ctx: &mut TxContext): Identity {
    new(profile_id, ctx)
  }
}