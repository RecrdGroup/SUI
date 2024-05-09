#[test_only]
module recrd::receipt_test {
    // === Imports ===
    use sui::test_scenario::{Self as ts};
    use std::string::{utf8};
    use recrd::core;
    use recrd::master::{Self, Sound};
    use recrd::receipt::{Self, Receipt};
    use recrd::master_test;

    // === Constants ===
    const ADMIN: address = @0xDECAF;
    const USER: address = @0xC0FFEE;
    const ORIGIN_REF: address = @0xFACE;
    const PARENT_REF: address = @0xBEEF;

    // === Errors ===
    const EInvalidMasterId: u64 = 1001;

    // === Tests ===
    
    #[test]
    public fun mints_and_burns_receipt() {
        let mut scenario = ts::begin(ADMIN);
        core::init_for_testing(ts::ctx(&mut scenario));
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

        // Mint Master
        let mut master = master_test::mint_master<Sound>(
            &mut scenario,
            utf8(b"Test Sound Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        let master_id = master.id<Sound>();

        // Admin creates a new receipt for user
        ts::next_tx(&mut scenario, ADMIN);
        {
            let registry = ts::take_shared<core::Registry>(&scenario);
            receipt::new(
                &admin_cap, 
                &mut master, 
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
            assert!(id == master_id, EInvalidMasterId);
            assert!(address == USER, EInvalidMasterId);
        };

        let _ = master::burn_master(&admin_cap, master);
        core::burn_admincap(admin_cap);
        ts::end(scenario);
    }
}