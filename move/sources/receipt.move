// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module recrd::receipt {
    // === Imports ===
    use sui::object::{Self, UID, ID};
    use sui::transfer::{Self, Receiving};
    use sui::tx_context::TxContext;
    use recrd::core::{Self, AdminCap, Registry};

    // === Friends ===
    friend recrd::profile;

    // === Errors ===
    const EWrongVersion: u64 = 1;

    // === Structs ===
    struct Receipt has key {
        id: UID,
        master_id: ID,
        user_profile: address,
    }

    /// Users who buy a `Master<T>` object will receive a receipt as proof of purchase sent
    /// to their profile. The receipt contains the `master_id` and `user_profile` of the purchase.
    /// We include the `master_id` to allow the user to move the `Master<T>` object to another profile.
    /// The `user_profile` is the Profile address of the user who made the purchase.
    /// We include the `user_profile` so that `Master<T>` is transferred to the correct profile.
    public fun new(
        _: &AdminCap, 
        master_id: ID, 
        profile: address, 
        registry: &Registry, 
        ctx: &mut TxContext
    ) {
        // Don't allow the issuance of new receipts if the core VERSION is not the same
        // with the version on Registry.
        assert!(core::is_valid_version(registry), EWrongVersion);

        transfer::transfer(Receipt {
            id: object::new(ctx),
            master_id,
            user_profile: profile,
        }, profile);
    }

    /// Receipt is burned to get the `master_id` and `user_profile` of the purchase.
    /// The `master_id` is returned to the sender to be used in the next moveCall of the PTB.
    public fun burn(receipt: Receipt): (ID, address) {
        // deconstruct and burn receipt
        let Receipt { id, master_id, user_profile } = receipt;
        object::delete(id);
       (master_id, user_profile)
    }

    /// Sender receives a receipt after the purchase resolves successfully for both parties.
    public(friend) fun receive(profile_id: &mut UID, receipt: Receiving<Receipt>): Receipt {
        transfer::receive<Receipt>(profile_id, receipt)
    }

}