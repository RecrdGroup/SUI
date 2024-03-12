
#[test_only]
module recrd::profile_test {

    use std::string::utf8;
    use sui::tx_context::{Self, TxContext};
    use sui::test_scenario::{Self as ts, Scenario};

    use recrd::core::{Self};
    use recrd::profile::{Self, Profile, Promise};

    const USERNAME: vector<u8> = b"username";
    const USER_ID: vector<u8> = b"user_id";
    const USER_PROFILE: address = @0xC0FEE;
    const ADMIN: address = @0xDECAF;

    const EInvalidAccessRights: u64 = 1;
    
    public fun ctx(): TxContext { tx_context::dummy() }


    // This test can't work with dummy context
    #[test]
    public fun mints_profile() {
        let ctx = ctx();
        let admin_cap = core::mint_for_testing(&mut ctx);
        profile::create_and_share(&admin_cap, utf8(USERNAME), utf8(USER_ID), &mut ctx);
        core::burn_for_testing(admin_cap);
    }

    // This test also needs accessors to properly check that we are minting as expected. 
    #[test]
    public fun mints_profile_test_scenario() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);
        profile::create_and_share(&admin_cap, utf8(USERNAME), utf8(USER_ID), ctx);
        // --- can check the state with test scenario ---
        ts::next_tx(test, ADMIN);
        let profile = ts::take_shared<Profile>(&scenario);
        // (!) however requires accessors which we don't need (!)
        ts::return_shared(profile);
        // ------
        core::burn_for_testing(admin_cap);
        ts::end(scenario);
    }



}