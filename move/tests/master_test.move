// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module recrd::master_test {
    // === Imports ===
    use std::string::{String, utf8};
    use std::option::{Self, Option};

    use sui::test_scenario::{Self as ts, Scenario};
    use sui::object::{Self, ID};
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
        EInvalidSaleStatus
    };

    // === Constants ===
    const ORIGIN_REF: address = @0xFACE;
    const PARENT_REF: address = @0xBEEF;
    const ADMIN: address = @0xDECAF;
    const USER_PROFILE: address = @0xC0FFEE;
    const USER_ROYALTY_BP: u16 = 1_000;
    const ON_SALE: u8 = 1;
    const SUSPENDED: u8 = 2;

    // === Errors ===
    const EInvalidMasterValue: u64 = 1001;
    const EInvalidMetadataValue: u64 = 1002;
    const EInvalidDisplayValue: u64 = 1003;

    // === Helpers ===

    public fun mint_master<T: drop>(
        scenario: &mut Scenario, 
        title: String, 
        parent: Option<ID>,
        origin: Option<ID>, 
    ): Master<T> {
        ts::next_tx(scenario, ADMIN);
        let ctx = ts::ctx(scenario);
        let admin_cap = core::mint_for_testing(ctx);

        let master = master::new<T>(
            &admin_cap,
            title,
            utf8(b"Test Description"),
            utf8(b"https://test.com/image"),
            utf8(b"https://test.com/media"),
            vector[utf8(b"test"), utf8(b"master")],
            object::id_from_address(USER_PROFILE),
            USER_ROYALTY_BP,
            parent,
            origin,
            ON_SALE,
            ctx
        );

        core::burn_for_testing(admin_cap);

        master
    }

    // === Tests ===

    #[test]
    public fun initializes() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);

        master::init_for_testing(ctx);

        // Validate Display fields for Video Master
        ts::next_tx(test, ADMIN);
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

            let master_display = ts::take_from_sender<Display<Master<Video>>>(test);
            let fields_vec = display::fields(&master_display);
            let (keys, values) = vec_map::into_keys_values(*fields_vec);
            assert!(keys == master_keys, EInvalidDisplayValue);
            assert!(values == master_values, EInvalidDisplayValue);

            ts::return_to_sender(test, master_display);
        };

        // Validate Display fields for Video Metadata
        ts::next_tx(test, ADMIN);
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

            let metadata_display = ts::take_from_sender<Display<Metadata<Video>>>(test);
            let fields_vec = display::fields(&metadata_display);
            let (keys, values) = vec_map::into_keys_values(*fields_vec);
            assert!(keys == metadata_keys, EInvalidDisplayValue);
            assert!(values == metadata_values, EInvalidDisplayValue);

            ts::return_to_sender(test, metadata_display);
        };

        ts::end(scenario);
    }

    #[test]
    public fun mints_video_master() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);

        let master = mint_master<Video>(
            test,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(test);

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
                master::meta_expressions(&metadata) == 0, 
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

        master::admin_burn_master(&admin_cap, master);
        core::burn_for_testing(admin_cap);
        ts::end(scenario);
    }

    #[test]
    public fun mints_audio_master() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);

        let master = mint_master<Sound>(
            test,
            utf8(b"Test Sound Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );


        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Sound>>(test);

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
                master::meta_expressions(&metadata) == 0, 
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

        master::admin_burn_master(&admin_cap, master);
        core::burn_for_testing(admin_cap);
        ts::end(scenario);
    }

    #[test]
    public fun burns_metadata() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);

        let master = master::new<Video>(
            &admin_cap,
            utf8(b"Test Video Master"),
            utf8(b"Test Description"),
            utf8(b"https://test.com/image"),
            utf8(b"https://test.com/media"),
            vector[utf8(b"test"), utf8(b"master")],
            object::id(&admin_cap),
            USER_ROYALTY_BP,
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF)),
            ON_SALE,
            ctx
        );

        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(test);
            master::admin_burn_metadata(&admin_cap, metadata);
        };

        master::admin_burn_master(&admin_cap, master);
        core::burn_for_testing(admin_cap);
        ts::end(scenario);
    }

    #[test]
    public fun updates_master() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);

        let master = mint_master<Video>(
            test,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        ts::next_tx(test, ADMIN);
        let metadata = ts::take_shared<Metadata<Video>>(test);

        // Update Master 
        ts::next_tx(test, ADMIN);
        {
            master::sync_title(&mut master, &metadata);
            master::sync_image_url(&mut master, &metadata);
            master::set_sale_status(&admin_cap, &mut master, SUSPENDED);
        };

        // Validate Updated Master fields
        ts::next_tx(test, ADMIN);
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
                master::sale_status(&master) == SUSPENDED, 
                EInvalidMasterValue
            );
        };

        // Update sale status to ON_SALE
        ts::next_tx(test, ADMIN);
        {
            master::set_sale_status(&admin_cap, &mut master, ON_SALE);
        };

        // Validate Updated sale status
        ts::next_tx(test, ADMIN);
        {
            assert!(master::sale_status(&master) == ON_SALE, EInvalidMasterValue);
        };

        let _ = master::admin_burn_master(&admin_cap, master);
        core::burn_for_testing(admin_cap);
        ts::return_shared(metadata);
        ts::end(scenario);
    }

    #[test]
    public fun updates_metadata() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);

        let master = mint_master<Video>(
            test,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        // Update Metadata
        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(test);
            
            master::set_title(&admin_cap, &mut metadata, utf8(b"Updated Title"));
            master::set_description(&admin_cap, &mut metadata, utf8(b"Updated Description"));
            master::set_hashtags(&admin_cap, &mut metadata, vector[utf8(b"updated"), utf8(b"master")]);
            master::set_image_url(&admin_cap, &mut metadata, utf8(b"image-url.com"));
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
        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(test);

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

        master::admin_burn_master(&admin_cap, master);
        core::burn_for_testing(admin_cap);
        ts::end(scenario);
    }

    #[test]
    public fun adds_hashtags() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);

        let master = mint_master<Video>(
            test,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        // Add 2 new hashtags
        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(test);
            master::add_hashtag(&admin_cap, &mut metadata, utf8(b"new"));
            master::add_hashtag(&admin_cap, &mut metadata, utf8(b"tag"));
            ts::return_shared(metadata);
        };

        // Validate Updated hashtags
        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(test);

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

        master::admin_burn_master(&admin_cap, master);
        core::burn_for_testing(admin_cap);
        ts::end(scenario);
    }

    #[test]
    public fun removes_hashtag() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);

        let master = mint_master<Video>(
            test,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        // Remove hashtag
        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(test);
            master::remove_hashtag(&admin_cap, &mut metadata, utf8(b"master"));
            ts::return_shared(metadata);
        };

        // Validate Updated Hashtags
        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(test);

            assert!(
                master::meta_hashtags(&metadata) == vector[utf8(b"test")], 
                EInvalidMetadataValue
            );

            ts::return_shared(metadata);
        };

        master::admin_burn_master(&admin_cap, master);
        core::burn_for_testing(admin_cap);
        ts::end(scenario);
    }

    // ~~~ Expected Failures ~~~

    #[test]
    #[expected_failure(abort_code = EInvalidSaleStatus)]
    public fun aborts_on_invalid_sale_status() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);

        let master = mint_master<Video>(
            test,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        ts::next_tx(test, ADMIN);
        {
            // Sale status 3 does not exist
            master::set_sale_status(&admin_cap, &mut master, 3);
        };

        master::admin_burn_master(&admin_cap, master);
        core::burn_for_testing(admin_cap);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EHashtagDoesNotExist)]
    public fun aborts_on_remove_non_existent_hashtag() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);

        let master = mint_master<Video>(
            test,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(test);
            // Trying to remove a hashtag that doesn't exist
            master::remove_hashtag(&admin_cap, &mut metadata, utf8(b"non-existent"));
            ts::return_shared(metadata);
        };

        master::admin_burn_master(&admin_cap, master);
        core::burn_for_testing(admin_cap);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidNewRevenueTotal)]
    public fun aborts_on_invalid_new_revenue_total() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);

        let master = mint_master<Video>(
            test,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        // Initial valid update
        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(test);
            master::set_revenue_total(&admin_cap, &mut metadata, 50);
            ts::return_shared(metadata);
        };

        // Follow-up invalid update
        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(test);
            master::set_revenue_total(&admin_cap, &mut metadata, 25);
            ts::return_shared(metadata);
        };

        master::admin_burn_master(&admin_cap, master);
        core::burn_for_testing(admin_cap);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidNewRevenuePaid)]
    public fun aborts_on_invalid_new_revenue_paid() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);

        let master = mint_master<Video>(
            test,
            utf8(b"Test Video Master"),
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF))
        );

        // Initial valid update
        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(test);
            master::set_revenue_paid(&admin_cap, &mut metadata, 30);
            ts::return_shared(metadata);
        };

        // Follow-up invalid update
        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(test);
            master::set_revenue_paid(&admin_cap, &mut metadata, 15);
            ts::return_shared(metadata);
        };

        master::admin_burn_master(&admin_cap, master);
        core::burn_for_testing(admin_cap);
        ts::end(scenario);
    }

}