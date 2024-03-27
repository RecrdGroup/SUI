module recrd::receipt {
    // === Imports ===
    use sui::object::{Self, UID, ID};
    use sui::transfer::{Self, Receiving};
    use sui::tx_context::TxContext;
    use recrd::core::AdminCap;

    // === Friends ===
    friend recrd::profile;

    // === Errors ===

    // === Constants ===

    // === Structs ===
    struct Receipt has key {
        id: UID,
        master_id: ID,
        user_profile: address,
    }

    public fun new(
        _: &AdminCap,
        master_id: ID,
        addr: address,
        ctx: &mut TxContext
    ) {
        let receipt = Receipt {
            id: object::new(ctx),
            master_id,
            user_profile: addr,
        };
        transfer::transfer(receipt, addr);
    }

    // @TODO: Maybe we shouldn't allow unrestricted burning, even though it would not be beneficial for anyone to do it.
    public fun burn(receipt: Receipt): (ID, address) {
        // deconstruct and burn receipt
        let Receipt { id, master_id, user_profile } = receipt;
        object::delete(id);
       (master_id, user_profile)
    }

    public(friend) fun receive(profile_id: &mut UID, receipt: Receiving<Receipt>): Receipt {
        transfer::receive(profile_id, receipt)
    }

}