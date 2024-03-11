
#[test_only]
module recrd::test_profile {

    use std::string::utf8;
    use sui::tx_context::{Self, TxContext};

    use recrd::core::{Self};
    use recrd::profile::{Self, Profile, Promise};

    const USERNAME: vector<u8> = b"username";
    const USER_ID: vector<u8> = b"user_id";
    const USER_PROFILE: address = @0xC0FEE;

    
    public fun ctx(): TxContext { tx_context::dummy() }


    #[test]
    public fun mints_profile() {
        let ctx = ctx();
        let admin_cap = core::mint_for_testing(&mut ctx);
        profile::create_and_share(&admin_cap, utf8(USERNAME), utf8(USER_ID), &mut ctx);
        core::burn_for_testing(admin_cap);
    }

    #[test]
    public fun admin_authorizes_address() {
        let ctx = ctx();
        let admin_cap = core::mint_for_testing(&mut ctx);
        let profile = profile::create_for_testing(utf8(USERNAME), utf8(USER_ID), &mut ctx);
        profile::authorize(&admin_cap, &mut profile, USER_PROFILE, 1, &mut ctx);
        core::burn_for_testing(admin_cap);
        profile::burn_for_testing(profile);
    }

}