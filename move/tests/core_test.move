#[test_only]
module recrd::core_test {


    // === Imports ===
    use sui::test_scenario::{Self as ts};

    use recrd::core::{Self, AdminCap}; 

    // === Constants ===
    const ADMIN: address = @0xDECAF;

    // === Errors ===

    #[test]
    public fun initializes() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);

        core::init_for_testing(ctx);

        ts::next_tx(test, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(test);
            ts::return_to_sender(test, admin_cap);
        };

        ts::end(scenario);
    }

    #[test]
    public fun mints_new_admin_cap() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);

        core::init_for_testing(ctx);
  
        ts::next_tx(test, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(test);
            let ctx = ts::ctx(test);
            let new_admin_cap = core::admin_new_cap(&admin_cap, ctx);
            core::burn_for_testing(new_admin_cap);
            ts::return_to_sender(test, admin_cap);
        };

        ts::next_tx(test, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(test);
            ts::return_to_sender(test, admin_cap);
        };

        ts::end(scenario);
    }

}