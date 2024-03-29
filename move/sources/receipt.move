module recrd::receipt {
    // === Imports ===
    use sui::object::{Self, UID, ID};
    use sui::transfer::{Self, Receiving};
    use sui::tx_context::TxContext;
    use recrd::core::AdminCap;

    // === Friends ===
    friend recrd::profile;

    // === Structs ===
    struct Receipt has key {
        id: UID,
        master_id: ID,
        user_profile: address,
    }

    /// Users who buy a `Master<T>` object will receive a receipt as proof of purchase.
    public fun new( _: &AdminCap, master_id: ID, addr: address, ctx: &mut TxContext) {
        transfer::transfer(Receipt {
            id: object::new(ctx),
            master_id,
            user_profile: addr,
        }, addr);
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
        transfer::receive(profile_id, receipt)
    }

}