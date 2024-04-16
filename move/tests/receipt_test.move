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
        core::init_for_testing(ts::ctx(&mut scenario));
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

        // Admin creates a new receipt for user
        ts::next_tx(&mut scenario, ADMIN);
        {
            let registry = ts::take_shared<core::Registry>(&scenario);
            receipt::new(
                &admin_cap, 
                object::id_from_address(MASTER_ID), 
                USER, 
                &registry, 
                ts::ctx(&mut scenario)
            );
            ts::return_shared(registry);
        };

        // User burns the receipt
        ts::next_tx(&mut scenario, USER);
        {
            let receipt = ts::take_from_sender<Receipt>(&scenario);
            let (id, address) = receipt::burn(receipt);
            assert!(id == object::id_from_address(MASTER_ID), EInvalidMasterId);
            assert!(address == USER, EInvalidMasterId);
        };

        core::burn_admincap(admin_cap);
        ts::end(scenario);
    }
}