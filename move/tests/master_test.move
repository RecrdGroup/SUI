// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module recrd::master_test {
    // === Imports ===
    use std::string::{String, utf8};
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::display::{Self, Display};
    use sui::vec_map::{Self};

    use recrd::core::{Self};
    use recrd::master::{
        Self, 
        Master, 
        Video, 
        Sound, 
        Metadata, 
        EHashtagDoesNotExist, 
        EInvalidNewRevenueTotal, 
        EInvalidNewRevenuePaid, 
        ESuspendedItemCannotBeListed,
        ESuspendedItemCannotBeRetained,
        EInvalidMetadataForMaster
    };

    // === Constants ===
    const ORIGIN_REF: address = @0xFACE;
    const PARENT_REF: address = @0xBEEF;
    const ADMIN: address = @0xDECAF;
    const USER: address = @0xB00;
    const USER_PROFILE: address = @0xC0FFEE;
    const USER_ROYALTY_BP: u16 = 1_000;
    const RETAINED: u8 = 1;
    const ON_SALE: u8 = 2;

    // === Errors ===
    const EInvalidMasterValue: u64 = 1001;
    const EInvalidMetadataValue: u64 = 1002;
    const EInvalidDisplayValue: u64 = 1003;

    // === Tests ===

    #[test]
    public fun initializes() {
        let mut scenario = ts::begin(ADMIN);

        master::init_for_testing(ts::ctx(&mut scenario));

        // Validate Display fields for Video Master
        ts::next_tx(&mut scenario, ADMIN);
        {
            let master_keys = vector[
                utf8(b"Name"),
                utf8(b"Image URL"),
                utf8(b"Media URL"),
                utf8(b"Metadata Ref"),
            ];

            let master_values = vector[
                utf8(b"{title}"),
                utf8(b"{image_url}"),
                utf8(b"{media_url}"),
                utf8(b"{metadata_ref}"),
            ];

            let master_display = ts::take_from_sender<Display<Master<Video>>>(&scenario);
            let fields_vec = display::fields(&master_display);
            let (keys, values) = vec_map::into_keys_values(*fields_vec);
            assert!(keys == master_keys, EInvalidDisplayValue);
            assert!(values == master_values, EInvalidDisplayValue);

            ts::return_to_sender(&scenario, master_display);
        };

        // Validate Display fields for Video Metadata
        ts::next_tx(&mut scenario, ADMIN);
        {
            let metadata_keys = vector[
                utf8(b"Title"),
                utf8(b"Description"),
                utf8(b"Image URL"),
                utf8(b"Media URL"),
                utf8(b"Hashtags"),
                utf8(b"Creator"),
                utf8(b"Parent"),
                utf8(b"Origin"),
                utf8(b"Expressions"),
            ];

            let metadata_values = vector[
                utf8(b"{title}"),
                utf8(b"{description}"),
                utf8(b"{image_url}"),
                utf8(b"{media_url}"),
                utf8(b"{hashtags}"),
                utf8(b"{creator_profile_id}"),
                utf8(b"{master_metadata_parent}"),
                utf8(b"{master_metadata_origin}"),
                utf8(b"{expressions}"),
            ];

            let metadata_display = ts::take_from_sender<Display<Metadata<Video>>>(&scenario);
            let fields_vec = display::fields(&metadata_display);
            let (keys, values) = vec_map::into_keys_values(*fields_vec);
            assert!(keys == metadata_keys, EInvalidDisplayValue);
            assert!(values == metadata_values, EInvalidDisplayValue);

            ts::return_to_sender(&scenario, metadata_display);
        };

        ts::end(scenario);
    }

    #[test]
    public fun mints_video_master() {
        let mut scenario = ts::begin(ADMIN);
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

        let master = mint_master<Video>(
            &mut scenario,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        ts::next_tx(&mut scenario, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(&scenario);

            // Validate Master fields
            assert!(
                master::metadata_ref(&master) == object::id(&metadata), 
                EInvalidMasterValue
            );
            assert!(
                master::title(&master) == utf8(b"Test Video Master"), 
                EInvalidMasterValue
            );
            assert!(
                master::image_url(&master) == utf8(b"https://test.com/image"), 
                EInvalidMasterValue
            );
            assert!(
                master::media_url(&master) == utf8(b"https://test.com/media"), 
                EInvalidMasterValue
            );
            assert!(
                master::sale_status(&master) == ON_SALE, 
                EInvalidMasterValue
            );

            // Validate Metadata fields
            assert!(
                master::meta_master_id(&metadata) == object::id(&master), 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_title(&metadata) == utf8(b"Test Video Master"), 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_description(&metadata) == utf8(b"Test Description"), 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_hashtags(&metadata) == vector[utf8(b"test"), utf8(b"master")], 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_creator_profile_id(&metadata) == object::id_from_address(USER_PROFILE), 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_royalty_percentage_bp(&metadata) == USER_ROYALTY_BP, 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_parent(&metadata) == option::some<ID>(
                    object::id_from_address(PARENT_REF)
                ), EInvalidMetadataValue
            );
            assert!(master::meta_origin(&metadata) == option::some<ID>(
                    object::id_from_address(ORIGIN_REF)
                ), EInvalidMetadataValue
            );
            assert!(
                master::meta_expressions(&metadata) == 2, 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_revenue_total(&metadata) == 0, 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_revenue_available(&metadata) == 0, 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_revenue_paid(&metadata) == 0, 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_revenue_pending(&metadata) == 0, 
                EInvalidMetadataValue
            );

            ts::return_shared(metadata);
        };

        master::burn_master(&admin_cap, master);
        core::burn_admincap(admin_cap);
        ts::end(scenario);
    }

    #[test]
    public fun mints_audio_master() {
        let mut scenario = ts::begin(ADMIN);
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

        let master = mint_master<Sound>(
            &mut scenario,
            utf8(b"Test Sound Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );


        ts::next_tx(&mut scenario, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Sound>>(&scenario);

            // Validate Master fields
            assert!(
                master::metadata_ref(&master) == object::id(&metadata), 
                EInvalidMasterValue
            );
            assert!(
                master::title(&master) == utf8(b"Test Sound Master"), 
                EInvalidMasterValue
            );
            assert!(
                master::image_url(&master) == utf8(b"https://test.com/image"), 
                EInvalidMasterValue
            );
            assert!(
                master::media_url(&master) == utf8(b"https://test.com/media"), 
                EInvalidMasterValue
            );
            assert!(
                master::sale_status(&master) == ON_SALE, 
                EInvalidMasterValue
            );

            // Validate Metadata fields
            assert!(
                master::meta_master_id(&metadata) == object::id(&master), 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_title(&metadata) == utf8(b"Test Sound Master"), 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_description(&metadata) == utf8(b"Test Description"), 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_hashtags(&metadata) == vector[utf8(b"test"), utf8(b"master")], 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_creator_profile_id(&metadata) == object::id_from_address(USER_PROFILE), 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_royalty_percentage_bp(&metadata) == USER_ROYALTY_BP, 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_parent(&metadata) == option::some<ID>(
                    object::id_from_address(PARENT_REF)
                ), EInvalidMetadataValue
            );
            assert!(master::meta_origin(&metadata) == option::some<ID>(
                    object::id_from_address(ORIGIN_REF)
                ), EInvalidMetadataValue
            );
            assert!(
                master::meta_expressions(&metadata) == 2, 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_revenue_total(&metadata) == 0, 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_revenue_available(&metadata) == 0, 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_revenue_paid(&metadata) == 0, 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_revenue_pending(&metadata) == 0, 
                EInvalidMetadataValue
            );

            ts::return_shared(metadata);
        };

        master::burn_master(&admin_cap, master);
        core::burn_admincap(admin_cap);
        ts::end(scenario);
    }

    #[test]
    public fun burns_metadata() {
        let mut scenario = ts::begin(ADMIN);
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));
        
        let master = mint_master<Video>(
            &mut scenario,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        ts::next_tx(&mut scenario, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(&scenario);
            master::burn_metadata(&admin_cap, metadata);
        };

        master::burn_master(&admin_cap, master);
        core::burn_admincap(admin_cap);
        ts::end(scenario);
    }

    #[test]
    public fun updates_master() {
        let mut scenario = ts::begin(ADMIN);
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

        let mut master = mint_master<Video>(
            &mut scenario,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        ts::next_tx(&mut scenario, ADMIN);
        let metadata = ts::take_shared<Metadata<Video>>(&scenario);

        // Update Master 
        ts::next_tx(&mut scenario, ADMIN);
        {
            master::sync_title(&mut master, &metadata);
            master::sync_image_url(&mut master, &metadata);
            master::list(&mut master);
        };

        // Validate Updated Master fields
        ts::next_tx(&mut scenario, ADMIN);
        {
            assert!(
                master::title(&master) == master::meta_title(&metadata), 
                EInvalidMasterValue
            );
            assert!(
                master::image_url(&master) == master::meta_image_url(&metadata), 
                EInvalidMasterValue
            );
            assert!(
                master::media_url(&master) == master::meta_media_url(&metadata), 
                EInvalidMasterValue
            );
            assert!(
                master::sale_status(&master) == ON_SALE, 
                EInvalidMasterValue
            );
        };

        ts::next_tx(&mut scenario, ADMIN);
        {
            master::unlist(&mut master);
        };

        // Validate Updated sale status
        ts::next_tx(&mut scenario, ADMIN);
        {
            assert!(master::sale_status(&master) == RETAINED, EInvalidMasterValue);
        };

        let _ = master::burn_master(&admin_cap, master);
        core::burn_admincap(admin_cap);
        ts::return_shared(metadata);
        ts::end(scenario);
    }

    #[test]
    public fun updates_metadata() {
        let mut scenario = ts::begin(ADMIN);
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

        let master = mint_master<Video>(
            &mut scenario,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        // Update Metadata
        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut metadata = ts::take_shared<Metadata<Video>>(&scenario);
            
            master::set_title(&master, &mut metadata, utf8(b"Updated Title"));
            master::set_description(&master, &mut metadata, utf8(b"Updated Description"));
            master::set_hashtags(&admin_cap, &mut metadata, vector[utf8(b"updated"), utf8(b"master")]);
            master::set_image_url(&master, &mut metadata, utf8(b"image-url.com"));
            master::set_media_url(&admin_cap, &mut metadata, utf8(b"media-url.com"));
            master::set_royalty_percentage_bp(&admin_cap, &mut metadata, 200);
            master::set_metadata_parent(&admin_cap, &mut metadata, option::none<ID>());
            master::set_metadata_origin(&admin_cap, &mut metadata, option::none<ID>());
            master::set_expressions(&admin_cap, &mut metadata, 1);
            master::set_revenue_total(&admin_cap, &mut metadata, 100);
            master::set_revenue_available(&admin_cap, &mut metadata, 50);
            master::set_revenue_paid(&admin_cap, &mut metadata, 25);
            master::set_revenue_pending(&admin_cap, &mut metadata, 25);

            ts::return_shared(metadata);
        };

        // Validate Updated Metadata fields
        ts::next_tx(&mut scenario, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(&scenario);

            assert!(
                master::meta_title(&metadata) == utf8(b"Updated Title"), 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_description(&metadata) == utf8(b"Updated Description"), 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_image_url(&metadata) == utf8(b"image-url.com"), 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_media_url(&metadata) == utf8(b"media-url.com"), 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_hashtags(&metadata) == vector[utf8(b"updated"), utf8(b"master")],
                EInvalidMetadataValue
            );
            assert!(
                master::meta_royalty_percentage_bp(&metadata) == 200, 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_parent(&metadata) == option::none<ID>(), 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_origin(&metadata) == option::none<ID>(), 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_expressions(&metadata) == 1, 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_revenue_total(&metadata) == 100,
                EInvalidMetadataValue
            );
            assert!(
                master::meta_revenue_available(&metadata) == 50, 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_revenue_paid(&metadata) == 25, 
                EInvalidMetadataValue
            );
            assert!(
                master::meta_revenue_pending(&metadata) == 25, 
                EInvalidMetadataValue
            );

            ts::return_shared(metadata);
        };

        master::burn_master(&admin_cap, master);
        core::burn_admincap(admin_cap);
        ts::end(scenario);
    }

    #[test]
    public fun adds_hashtags() {
        let mut scenario = ts::begin(ADMIN);
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

        let master = mint_master<Video>(
            &mut scenario,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        // Add 2 new hashtags
        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut metadata = ts::take_shared<Metadata<Video>>(&scenario);
            master::add_hashtag(&admin_cap, &mut metadata, utf8(b"new"));
            master::add_hashtag(&admin_cap, &mut metadata, utf8(b"tag"));
            ts::return_shared(metadata);
        };

        // Validate Updated hashtags
        ts::next_tx(&mut scenario, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(&scenario);

            assert!(
                master::meta_hashtags(&metadata) == vector[
                    utf8(b"test"), 
                    utf8(b"master"), 
                    utf8(b"new"), 
                    utf8(b"tag")
                ], EInvalidMetadataValue
            );

            ts::return_shared(metadata);
        };

        master::burn_master(&admin_cap, master);
        core::burn_admincap(admin_cap);
        ts::end(scenario);
    }

    #[test]
    public fun removes_hashtag() {
        let mut scenario = ts::begin(ADMIN);
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

        let master = mint_master<Video>(
            &mut scenario,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        // Remove hashtag
        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut metadata = ts::take_shared<Metadata<Video>>(&scenario);
            master::remove_hashtag(&admin_cap, &mut metadata, utf8(b"master"));
            ts::return_shared(metadata);
        };

        // Validate Updated Hashtags
        ts::next_tx(&mut scenario, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(&scenario);

            assert!(
                master::meta_hashtags(&metadata) == vector[utf8(b"test")], 
                EInvalidMetadataValue
            );

            ts::return_shared(metadata);
        };

        master::burn_master(&admin_cap, master);
        core::burn_admincap(admin_cap);
        ts::end(scenario);
    }

    // ~~~ Expected Failures ~~~

    #[test]
    #[expected_failure(abort_code = ESuspendedItemCannotBeListed)]
    public fun aborts_on_listing_suspended_master() {
        let mut scenario = ts::begin(ADMIN);
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

        let mut master = mint_master<Video>(
            &mut scenario,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        ts::next_tx(&mut scenario, USER);
        {
            // Suspend master
            master::suspend(&admin_cap, &mut master);
        };

        ts::next_tx(&mut scenario, USER);
        {
            // User tries to list for sale
            master::list(&mut master);
        };

        master::burn_master(&admin_cap, master);
        core::burn_admincap(admin_cap);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ESuspendedItemCannotBeRetained)]
    public fun aborts_on_retaining_suspended_master() {
        let mut scenario = ts::begin(ADMIN);
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

        let mut master = mint_master<Video>(
            &mut scenario,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        ts::next_tx(&mut scenario, USER);
        {
            // Suspend master
            master::suspend(&admin_cap, &mut master);
        };

        ts::next_tx(&mut scenario, USER);
        {
            // User tries to list for sale
            master::unlist(&mut master);
        };

        master::burn_master(&admin_cap, master);
        core::burn_admincap(admin_cap);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EHashtagDoesNotExist)]
    public fun aborts_on_remove_non_existent_hashtag() {
        let mut scenario = ts::begin(ADMIN);
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

        let master = mint_master<Video>(
            &mut scenario,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut metadata = ts::take_shared<Metadata<Video>>(&scenario);
            // Trying to remove a hashtag that doesn't exist
            master::remove_hashtag(&admin_cap, &mut metadata, utf8(b"non-existent"));
            ts::return_shared(metadata);
        };

        master::burn_master(&admin_cap, master);
        core::burn_admincap(admin_cap);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidNewRevenueTotal)]
    public fun aborts_on_invalid_new_revenue_total() {
        let mut scenario = ts::begin(ADMIN);
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

        let master = mint_master<Video>(
            &mut scenario,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        // Initial valid update
        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut metadata = ts::take_shared<Metadata<Video>>(&scenario);
            master::set_revenue_total(&admin_cap, &mut metadata, 50);
            ts::return_shared(metadata);
        };

        // Follow-up invalid update
        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut metadata = ts::take_shared<Metadata<Video>>(&scenario);
            master::set_revenue_total(&admin_cap, &mut metadata, 25);
            ts::return_shared(metadata);
        };

        master::burn_master(&admin_cap, master);
        core::burn_admincap(admin_cap);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidNewRevenuePaid)]
    public fun aborts_on_invalid_new_revenue_paid() {
        let mut scenario = ts::begin(ADMIN);
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

        let master = mint_master<Video>(
            &mut scenario,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        // Initial valid update
        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut metadata = ts::take_shared<Metadata<Video>>(&scenario);
            master::set_revenue_paid(&admin_cap, &mut metadata, 30);
            ts::return_shared(metadata);
        };

        // Follow-up invalid update
        ts::next_tx(&mut scenario, ADMIN);
        {
            let mut metadata = ts::take_shared<Metadata<Video>>(&scenario);
            master::set_revenue_paid(&admin_cap, &mut metadata, 15);
            ts::return_shared(metadata);
        };

        master::burn_master(&admin_cap, master);
        core::burn_admincap(admin_cap);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidMetadataForMaster)]
    public fun aborts_on_metadata_master_miss_match_when_syncing() {
        let mut scenario = ts::begin(ADMIN);
        let admin_cap = core::mint_for_testing(ts::ctx(&mut scenario));

        let mut master = mint_master<Video>(
            &mut scenario,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        ts::next_tx(&mut scenario, ADMIN);
        let mut metadata = ts::take_shared<Metadata<Video>>(&scenario);


        // Update Metadata
        ts::next_tx(&mut scenario, ADMIN);
        {
            master::set_title<Video>(&master, &mut metadata, utf8(b"A New title"));
        };

        let _impostor_master = mint_master<Video>(
            &mut scenario,
            utf8(b"Test Video Master but different"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        ts::next_tx(&mut scenario, ADMIN);
        let impostor_metadata = ts::take_shared<Metadata<Video>>(&scenario);


        // Sync Master with the wrong metadata
        ts::next_tx(&mut scenario, ADMIN);
        {
            master::sync_title(&mut master, &impostor_metadata);
        };


        let _ = master::burn_master(&admin_cap, master);
        let _ = master::burn_master(&admin_cap, _impostor_master);
        core::burn_admincap(admin_cap);
        ts::return_shared(metadata);
        ts::return_shared(impostor_metadata);
        ts::end(scenario);
    }


    // === Helpers ===

    public fun mint_master<T: drop>(
        scenario: &mut Scenario, 
        title: String, 
        parent: Option<ID>,
        origin: Option<ID>, 
    ): Master<T> {
        ts::next_tx(scenario, ADMIN);
        let admin_cap = core::mint_for_testing(ts::ctx(scenario));

        let master = master::new<T>(
            &admin_cap, // admin cap
            title, // title
            utf8(b"Test Description"), // description
            utf8(b"https://test.com/image"), // image url
            utf8(b"https://test.com/media"), // media url
            vector[utf8(b"test"), utf8(b"master")], // hashtags
            object::id_from_address(USER_PROFILE), // creator profile id
            USER_ROYALTY_BP, // royalty percentage
            parent, // parent metadata
            origin, // origin metadata
            2, // expressions
            0, // revenue total
            0, // revenue available
            0, // revenue paid
            0, // revenue pending
            ON_SALE,
            ts::ctx(scenario)
        );

        core::burn_admincap(admin_cap);

        master
    }
}