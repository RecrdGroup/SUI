module recrd::receipt {
    // === Imports ===
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use recrd::core::AdminCap;

    // === Friends ===

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

    public fun burn(receipt: Receipt) {
        // deconstruct and burn receipt
        let Receipt { id, master_id: _, user_profile: _ } = receipt;
        object::delete(id);
    }

}