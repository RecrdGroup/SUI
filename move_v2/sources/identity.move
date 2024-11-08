// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
module recrd::identity {
  use recrd::core::AdminCap;

  // === Custom Receivers ===
  use fun new as ID.new;

  #[error]
  const EDeprecatedCall: vector<u8> = b"This function call is deprecated in the V2 implementation of Profile.";

  // Profile identity for users to link their account to their Profile. 
  public struct Identity has key {
    id: UID,
    profile: ID,
  }

  // === Admin Functions ===

  /// Admin can send more Identities to users that have existing Profile. 
  #[allow(dead_code)]
  public fun admin_new(_: &AdminCap, profile_id: ID, ctx: &mut TxContext): Identity {
    // Throws a deprecated call error.
    abort EDeprecatedCall;
    profile_id.new(ctx)
  }

  /// Admin can transfer Identities to other users.
  #[allow(dead_code)]
  public fun admin_transfer(_: &AdminCap, self: Identity, addr: address) {
    // Throws a deprecated call error.
    abort EDeprecatedCall;
    self.transfer(addr);
  }

  /// Functionality to delete an Identity object.
  public fun delete(self: Identity) {
    let Identity {id, profile: _} = self;
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