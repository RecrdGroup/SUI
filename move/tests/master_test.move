
#[test_only]
module recrd::master_test {
    use std::string::utf8;
    use std::option;

    use sui::test_scenario::{Self as ts};
    use sui::object::{Self, ID};

    use recrd::core::{Self};
    use recrd::master::{Self, Video, Sound, Metadata};

    const ORIGIN_REF: address = @0xFACE;
    const PARENT_REF: address = @0xBEEF;
    const ADMIN: address = @0xDECAF;
    const ON_SALE: u8 = 1;

    const EInvalidMasterValue: u64 = 1001;
    const EInvalidMetadataValue: u64 = 1002;

    #[test]
    public fun mints_video_master() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);

        let master = master::new<Video>(
            &admin_cap,
            utf8(b"Test Video Master"),
            utf8(b"https://test.com/image"),
            utf8(b"Test Description"),
            vector[utf8(b"test"), utf8(b"master")],
            object::id(&admin_cap),
            100,
            option::some<ID>(object::id_from_address(PARENT_REF)),
            option::some<ID>(object::id_from_address(ORIGIN_REF)),
            ON_SALE,
            ctx
        );

        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Video>>(test);

            // Validate Master fields
            assert!(master::metadata_ref(&master) == object::id(&metadata), EInvalidMasterValue);
            assert!(master::title(&master) == utf8(b"Test Video Master"), EInvalidMasterValue);
            assert!(master::image_url(&master) == utf8(b"https://test.com/image"), EInvalidMasterValue);
            assert!(master::sale_status(&master) == ON_SALE, EInvalidMasterValue);

            // Validate Metadata fields
            assert!(master::master_id(&metadata) == object::id(&master), EInvalidMetadataValue);
            assert!(master::description(&metadata) == utf8(b"Test Description"), EInvalidMetadataValue);
            assert!(master::hashtags(&metadata) == vector[utf8(b"test"), utf8(b"master")], EInvalidMetadataValue);
            assert!(master::creator_profile_id(&metadata) == object::id(&admin_cap), EInvalidMetadataValue);
            assert!(master::royalty_percentage_bp(&metadata) == 100, EInvalidMetadataValue);
            assert!(master::master_metadata_parent(&metadata) == option::some<ID>(object::id_from_address(PARENT_REF)), EInvalidMetadataValue);
            assert!(master::master_metadata_origin(&metadata) == option::some<ID>(object::id_from_address(ORIGIN_REF)), EInvalidMetadataValue);
            assert!(master::expressions(&metadata) == 0, EInvalidMetadataValue);
            assert!(master::revenue_total(&metadata) == 0, EInvalidMetadataValue);
            assert!(master::revenue_available(&metadata) == 0, EInvalidMetadataValue);
            assert!(master::revenue_paid(&metadata) == 0, EInvalidMetadataValue);
            assert!(master::revenue_pending(&metadata) == 0, EInvalidMetadataValue);

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

        let master = master::new<Sound>(
            &admin_cap,
            utf8(b"Test Sound Master"),
            utf8(b"https://test.com/image"),
            utf8(b"Test Description"),
            vector[utf8(b"test"), utf8(b"master")],
            object::id(&admin_cap),
            100,
            option::none<ID>(),
            option::some<ID>(object::id_from_address(ORIGIN_REF)),
            ON_SALE,
            ctx
        );

        ts::next_tx(test, ADMIN);
        {
            let metadata = ts::take_shared<Metadata<Sound>>(test);

            // Validate Master fields
            assert!(master::metadata_ref(&master) == object::id(&metadata), EInvalidMasterValue);
            assert!(master::title(&master) == utf8(b"Test Sound Master"), EInvalidMasterValue);
            assert!(master::image_url(&master) == utf8(b"https://test.com/image"), EInvalidMasterValue);
            assert!(master::sale_status(&master) == ON_SALE, EInvalidMasterValue);

            // Validate Metadata fields
            assert!(master::master_id(&metadata) == object::id(&master), EInvalidMetadataValue);
            assert!(master::description(&metadata) == utf8(b"Test Description"), EInvalidMetadataValue);
            assert!(master::hashtags(&metadata) == vector[utf8(b"test"), utf8(b"master")], EInvalidMetadataValue);
            assert!(master::creator_profile_id(&metadata) == object::id(&admin_cap), EInvalidMetadataValue);
            assert!(master::royalty_percentage_bp(&metadata) == 100, EInvalidMetadataValue);
            assert!(master::master_metadata_parent(&metadata) == option::none<ID>(), EInvalidMetadataValue);
            assert!(master::master_metadata_origin(&metadata) == option::some<ID>(object::id_from_address(ORIGIN_REF)), EInvalidMetadataValue);
            assert!(master::expressions(&metadata) == 0, EInvalidMetadataValue);
            assert!(master::revenue_total(&metadata) == 0, EInvalidMetadataValue);
            assert!(master::revenue_available(&metadata) == 0, EInvalidMetadataValue);
            assert!(master::revenue_paid(&metadata) == 0, EInvalidMetadataValue);
            assert!(master::revenue_pending(&metadata) == 0, EInvalidMetadataValue);

            ts::return_shared(metadata);
        };

        master::admin_burn_master(&admin_cap, master);
        core::burn_for_testing(admin_cap);
        ts::end(scenario);
    }

    #[test]
    public fun burn_metadata() {
        let scenario = ts::begin(ADMIN);
        let test = &mut scenario;
        let ctx = ts::ctx(test);
        let admin_cap = core::mint_for_testing(ctx);

        let master = master::new<Video>(
            &admin_cap,
            utf8(b"Test Video Master"),
            utf8(b"https://test.com/image"),
            utf8(b"Test Description"),
            vector[utf8(b"test"), utf8(b"master")],
            object::id(&admin_cap),
            100,
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



}