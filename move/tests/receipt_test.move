#[test_only]
module recrd::receipt_test {
    // === Imports ===
    use sui::test_scenario::{Self as ts};
    use sui::object;
    use recrd::core;
    use recrd::receipt::{Self, Receipt};

    // === Constants ===
    const ADMIN: address = @0xDECAF;
    const USER: address = @0xFACE;
    const MASTER_ID: address = @0xC0FFEE;

    // === Errors ===
    const EInvalidMasterId: u64 = 1001;

    // === Tests ===
    
    #[test]
    public fun mints_and_burns_receipt() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);

        // Admin creates a new receipt for user
        ts::next_tx(test, ADMIN);
        {
            let ctx = ts::ctx(test);
            receipt::new(&admin_cap, object::id_from_address(MASTER_ID), USER, ctx);
        };

        // User burns the receipt
        ts::next_tx(test, USER);
        {
            let receipt = ts::take_from_sender<Receipt>(test);
            let (id, address) = receipt::burn(receipt);
            assert!(id == object::id_from_address(MASTER_ID), EInvalidMasterId);
            assert!(address == USER, EInvalidMasterId);
        };

        core::burn_for_testing(admin_cap);
        ts::end(scenario);
    }
}