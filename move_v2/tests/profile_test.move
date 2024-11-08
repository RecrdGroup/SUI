
#[test_only]
module recrd::profile_test {
    // === Imports ===
    use std::string::utf8;
    use sui::test_scenario::{Self as ts, Scenario};

    use recrd::core::{Self};
    use recrd::profile::{Self, Profile, ENewValueShouldBeHigher, ENotAuthorized, EAuthorizationsExist, EDeprecatedCall};
    use recrd::identity::{Self, Identity};

    // === Constants ===
    const USERNAME: vector<u8> = b"username";
    const USER_ID: vector<u8> = b"user_id";
    const USER_PROFILE: address = @0xC0FFEE;
    const ADMIN: address = @0xDECAF;
    const USER: address = @0xB00;

    // === Errors ===
    const EInvalidAccessRights: u64 = 1;
    const EInvalidFieldValue: u64 = 2;
    
    public fun ctx(): TxContext { tx_context::dummy() }

    // === Helpers ===
    public fun create_profile(scenario: &mut Scenario) {
        ts::next_tx(scenario, ADMIN);
        let ctx = ts::ctx(scenario);
        let admin_cap = core::mint_for_testing(ctx);
        profile::new(
            &admin_cap, 
            utf8(USER_ID), 
            utf8(USERNAME), 
            USER,
            ctx
        );
        core::burn_admincap(admin_cap);
    }

    public fun create_profile_for_testing(scenario: &mut Scenario): Profile {
        ts::next_tx(scenario, ADMIN);
        let ctx = ts::ctx(scenario);
        let profile = profile::create_for_testing(
            utf8(USER_ID),
            utf8(USERNAME),
            ctx
        );

        ts::next_tx(scenario, USER);
        let ctx = ts::ctx(scenario);
        let identity = identity::create_for_testing(object::id(&profile), ctx);
        identity::transfer(identity, ctx.sender());
        profile
    }

    public fun authorize_user(scenario: &mut Scenario, profile: &mut Profile, user: address, role: u8) {
        ts::next_tx(scenario, ADMIN);
        let ctx = ts::ctx(scenario);
        let admin_cap = core::mint_for_testing(ctx);
        profile::authorize(&admin_cap, profile, user, role);
        core::burn_admincap(admin_cap);
    }

    public fun deauthorize_user(scenario: &mut Scenario, profile: &mut Profile, user: address) {
        ts::next_tx(scenario, ADMIN);
        let ctx = ts::ctx(scenario);
        let admin_cap = core::mint_for_testing(ctx);
        profile::deauthorize(&admin_cap, profile, user);
        core::burn_admincap(admin_cap);
    }


    // === Tests ===

    #[test]
    public fun deletes_profile() {
        let mut scenario = ts::begin(ADMIN);
        let profile = create_profile_for_testing(&mut scenario);

        // Deletes profile
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::delete(&admin_cap, profile);
            core::burn_admincap(admin_cap);
        };

        ts::end(scenario);
    }

    #[test]
    public fun deletes_identity() {
        let mut scenario = ts::begin(ADMIN);
        let profile = create_profile_for_testing(&mut scenario);

        // Delete user's identity
        ts::next_tx(&mut scenario, USER);
        {
            let identity = ts::take_from_sender<Identity>(&scenario);
            identity.delete();
        };

        // Deletes profile
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::delete(&admin_cap, profile);
            core::burn_admincap(admin_cap);
        };

        ts::end(scenario);
    }

    #[test]
    public fun admin_authorizes_address() {
        let mut scenario = ts::begin(ADMIN);
        let mut profile = create_profile_for_testing(&mut scenario);

        // --- Authorize user ---
        ts::next_tx(&mut scenario, ADMIN);
        {
            authorize_user(&mut scenario, &mut profile, USER_PROFILE, 100);
        };

        // --- Assert the access rights ---
        ts::next_tx(&mut scenario, ADMIN);
        {
            let user_access = profile::access_rights(&profile, USER_PROFILE);
            assert!(user_access == 100, EInvalidAccessRights);
        };

        // Deletes profile
        ts::next_tx(&mut scenario, ADMIN);
        {
            deauthorize_user(&mut scenario, &mut profile, USER_PROFILE);
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::delete(&admin_cap, profile);
            core::burn_admincap(admin_cap);
        };

        ts::end(scenario);
    }

    #[test]
    public fun admin_updates_profile_fields() {
        let mut scenario = ts::begin(ADMIN);

        let mut profile = create_profile_for_testing(&mut scenario);

        // --- Update the profile fields ---
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::authorize(&admin_cap, &mut profile, ADMIN, 200);
            profile::update_watch_time(&mut profile, 10, ts::ctx(&mut scenario));
            profile::update_videos_watched(&mut profile, 20, ts::ctx(&mut scenario)); 
            profile::update_adverts_watched(&mut profile, 30, ts::ctx(&mut scenario));
            profile::update_number_of_followers(&mut profile, 40, ts::ctx(&mut scenario));
            profile::update_number_of_following(&mut profile, 50, ts::ctx(&mut scenario));
            profile::update_ad_revenue(&admin_cap, &mut profile, 60);
            profile::update_commission_revenue(&admin_cap, &mut profile, 70);
            core::burn_admincap(admin_cap);
        };

        // --- Check the Profile state ---
        ts::next_tx(&mut scenario, ADMIN);
        {
            assert!(profile::watch_time(&profile) == 10, EInvalidFieldValue);
            assert!(profile::videos_watched(&profile) == 20, EInvalidFieldValue);
            assert!(profile::adverts_watched(&profile) == 30, EInvalidFieldValue);
            assert!(profile::number_of_followers(&profile) == 40, EInvalidFieldValue);
            assert!(profile::number_of_following(&profile) == 50, EInvalidFieldValue);
            assert!(profile::ad_revenue(&profile) == 60, EInvalidFieldValue);
            assert!(profile::commission_revenue(&profile) == 70, EInvalidFieldValue);
        };

        // Deletes profile
        ts::next_tx(&mut scenario, ADMIN);
        {
            deauthorize_user(&mut scenario, &mut profile, ADMIN);
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::delete(&admin_cap, profile);
            core::burn_admincap(admin_cap);
        };
        ts::end(scenario);
    }

    // === Expected failures ===
    #[test]
    #[expected_failure(abort_code = EDeprecatedCall)]
    public fun mints_profile_v1() {
        let mut scenario = ts::begin(ADMIN);
        create_profile(&mut scenario);

        // --- Check the Profile state ---
        ts::next_tx(&mut scenario, ADMIN);
        {
            let profile = ts::take_shared<Profile>(&scenario);
            assert!(profile::username(&profile) == utf8(USERNAME), EInvalidFieldValue);
            assert!(profile::user_id(&profile) == utf8(USER_ID), EInvalidFieldValue);
            // The bellow check would correctly throw that the address could not be found. 
            // Checked in a following expected_failure test.
            // assert!(profile::access_rights(&profile, USER_PROFILE) == 0, EInvalidAccessRights);
            assert!(profile::watch_time(&profile) == 0, EInvalidFieldValue);
            assert!(profile::videos_watched(&profile) == 0, EInvalidFieldValue);
            assert!(profile::adverts_watched(&profile) == 0, EInvalidFieldValue);
            assert!(profile::number_of_followers(&profile) == 0, EInvalidFieldValue);
            assert!(profile::number_of_following(&profile) == 0, EInvalidFieldValue);
            assert!(profile::ad_revenue(&profile) == 0, EInvalidFieldValue);
            assert!(profile::commission_revenue(&profile) == 0, EInvalidFieldValue);
            ts::return_shared(profile);
        };

        // --- Check the user has received the Identity --- 
        ts::next_tx(&mut scenario, USER);
        {
            let profile_cap = ts::take_from_sender<Identity>(&scenario);
            ts::return_to_sender(&scenario, profile_cap);
        };

        ts::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code = ENewValueShouldBeHigher)]
    public fun updates_watch_time_with_invalid_value() {
        let mut scenario = ts::begin(ADMIN);

        let mut profile = create_profile_for_testing(&mut scenario);
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::authorize(&admin_cap, &mut profile, USER, 120);
            core::burn_admincap(admin_cap);
        };

        // --- Update the profile watch time with an invalid value ---
        ts::next_tx(&mut scenario, USER);
        {
            // The new value should be higher than the current one
            profile::update_watch_time(&mut profile, 0, ts::ctx(&mut scenario));
        };

        // Deletes profile
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::delete(&admin_cap, profile);
            core::burn_admincap(admin_cap);
        };
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ENewValueShouldBeHigher)]
    public fun updates_videos_watched_with_invalid_value() {
        let mut scenario = ts::begin(ADMIN);

        let mut profile = create_profile_for_testing(&mut scenario);
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::authorize(&admin_cap, &mut profile, USER, 120);
            core::burn_admincap(admin_cap);
        };

        // --- Update the profile watched videos with an invalid value ---
        ts::next_tx(&mut scenario, USER);
        {
            // The new value should be higher than the current one
            profile::update_videos_watched(&mut profile, 0, ts::ctx(&mut scenario));
        };

        // Deletes profile
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::delete(&admin_cap, profile);
            core::burn_admincap(admin_cap);
        };
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ENewValueShouldBeHigher)]
    public fun updates_adverts_watched_with_invalid_value() {
        let mut scenario = ts::begin(ADMIN);

        let mut profile = create_profile_for_testing(&mut scenario);
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::authorize(&admin_cap, &mut profile, USER, 120);
            core::burn_admincap(admin_cap);
        };

        // --- Update the profile watched adverts with an invalid value ---
        ts::next_tx(&mut scenario, USER);
        {
            // The new value should be higher than the current one
            profile::update_adverts_watched(&mut profile, 0, ts::ctx(&mut scenario));
        };

        // Deletes profile
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::delete(&admin_cap, profile);
            core::burn_admincap(admin_cap);
        };
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ENewValueShouldBeHigher)]
    public fun admin_updates_ad_revenue_with_invalid_value() {
        let mut scenario = ts::begin(ADMIN);

        let mut profile = create_profile_for_testing(&mut scenario);
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::authorize(&admin_cap, &mut profile, USER, 120);
            core::burn_admincap(admin_cap);
        };

        // --- Update the profile ad revenue with an invalid value ---
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::authorize(&admin_cap, &mut profile, ADMIN, 200);
            
            // The new value should be higher than the current one
            profile::update_ad_revenue(&admin_cap, &mut profile, 0);
            core::burn_admincap(admin_cap);
        };

        // Deletes profile
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::delete(&admin_cap, profile);
            core::burn_admincap(admin_cap);
        };
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ENewValueShouldBeHigher)]
    public fun admin_updates_commission_revenue_with_invalid_value() {
        let mut scenario = ts::begin(ADMIN);

        let mut profile = create_profile_for_testing(&mut scenario);

        // --- Update the profile commission revenue with an invalid value ---
        ts::next_tx(&mut scenario, ADMIN);
        {
            let ctx = ts::ctx(&mut scenario);
            let admin_cap = core::mint_for_testing(ctx);
            // The new value should be higher than the current one
            profile::update_commission_revenue(&admin_cap, &mut profile, 0);
            core::burn_admincap(admin_cap);
        };

        // Deletes profile
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::delete(&admin_cap, profile);
            core::burn_admincap(admin_cap);
        };
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ENotAuthorized)]
    public fun trying_to_read_access_of_not_registered_address() {
        let mut scenario = ts::begin(ADMIN);

        let profile = create_profile_for_testing(&mut scenario);

        // --- Trying to read the access rights of an address that has not been authorized ---
        ts::next_tx(&mut scenario, ADMIN);
        {
            profile::access_rights(&profile, USER_PROFILE);
        };

        // Deletes profile
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::delete(&admin_cap, profile);
            core::burn_admincap(admin_cap);
        };
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EAuthorizationsExist)]
    public fun deletes_non_empty_authorization_profile() {
        let mut scenario = ts::begin(ADMIN);
        let mut profile = create_profile_for_testing(&mut scenario);

        // Add an authorization
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::authorize(&admin_cap, &mut profile, USER_PROFILE, 100);
            core::burn_admincap(admin_cap);
        };

        // Deletes profile
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
            profile::delete(&admin_cap, profile);
            core::burn_admincap(admin_cap);
        };

        ts::end(scenario);
    }

}