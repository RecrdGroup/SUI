// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Master purchases that occur on the platform are recorded on chain by creating a Receipt upon 
/// successful transaction. The receipt can be used as proof of funds transferred
/// to the seller. Allows the user to transfer a `Master<T>` object to their profile by 
/// prooving the particular purchase with the receipt.
module recrd::receipt {
    // === Imports ===
    use sui::transfer::{Receiving};
    use recrd::core::{AdminCap, Registry};
    use recrd::master::{Self, Master};

    // === Errors ===
    const EWrongVersion: u64 = 1;
    const EMasterNotOnSale: u64 = 2;

    // On sale state is when the master is on sale
    const ON_SALE: u8 = 2;

    // === Structs ===
    public struct Receipt has key {
        id: UID,
        master_id: ID,
        user_profile: address,
    }

    /// Users who buy a `Master<T>` object will receive a receipt as proof of purchase 
    /// sent to their profile. The receipt contains the `master_id` and `user_profile` 
    /// of the purchase.
    /// We require the `Master<T>` object of interest as an argument in order to 
    /// update its status to CLAIMED since the buyer has paid for it already, and
    /// we also include the Master ID in the `Receipt` so that the user will be able
    /// to successfully claim the Master upon completing the purchase.
    /// The `user_profile` is the Profile address of the user who made the purchase.
    /// We include the `user_profile` so that `Master<T>` is transferred to the 
    /// correct profile.
    public fun new<T>(
        _: &AdminCap, 
        master: &mut Master<T>, 
        profile: address, 
        registry: &Registry, 
        ctx: &mut TxContext
    ) {
        // Don't allow the issuance of new receipts if the core VERSION is not the same
        // with the version on Registry.
        assert!(registry.is_valid_version(), EWrongVersion);
        
        // Issue a Receipt for Master only if its status is ON_SALE
        assert!(master.sale_status<T>() == ON_SALE, EMasterNotOnSale);

        // Update Master status to CLAIMED to halt further updates until selling and
        // `Receipt` resolution is completed.
        master::claim<T>(master);

        transfer::transfer(Receipt {
            id: object::new(ctx),
            master_id: master::id<T>(master),
            user_profile: profile,
        }, profile);
    }

    /// Receipt is burned to get the `master_id` and `user_profile` of the purchase.
    /// The `master_id` is returned to the sender to be used in receiving `Master`.
    public(package) fun burn(receipt: Receipt): (ID, address) {
        // deconstruct and burn receipt
        let Receipt { id, master_id, user_profile } = receipt;
        id.delete();
        
       (master_id, user_profile)
    }

    /// Sender receives a receipt after the purchase resolves successfully for both
    /// parties.
    public(package) fun receive(
        profile_id: &mut UID, receipt: Receiving<Receipt>
    ): Receipt {
        transfer::receive<Receipt>(profile_id, receipt)
    }

}