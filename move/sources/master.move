// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// All videos and sounds are represented as Master objects. 
/// MasterMetadata<T> will hold all master-related metadata.
/// Master<T> is the proof of ownership owned object that users 
/// will have in order to prove that they own a Master. 
module recrd::master {

  // === Imports ===
  use std::string::{String, utf8};
  use sui::package;
  use sui::display;
  use recrd::core::AdminCap;
  
  // === Errors ===
  const EHashtagDoesNotExist: u64 = 1;
  const EInvalidNewRevenueTotal: u64 = 2;
  const EInvalidNewRevenuePaid: u64 = 3;
  const ESuspendedItemCannotBeListed: u64 = 4;
  const ESuspendedItemCannotBeRetained: u64 = 5;
  const EInvalidMetadataForMaster: u64 = 6;
  const EItemHasBeenClaimed: u64 = 7;

  // === Constants ===
  const RETAINED: u8 = 1;
  const ON_SALE: u8 = 2;
  const SUSPENDED: u8 = 3;
  const CLAIMED: u8 = 4;

  // === Structs ===

  // Define an OTW to the `Publisher` object for the sender.
  public struct MASTER has drop {}

  // Available types for T in Master and Metadata.
  public struct Video has drop {}
  public struct Sound has drop {}

  // Master object that will be the proof of ownership for the master.
  public struct Master<phantom T> has key, store {
    // unique ID for master
    id: UID,
    // reference ID of the master metadata object
    metadata_ref: ID,
    // title of master (needed for display)
    title: String,
    // URL for master video or audio cover (needed for display)
    image_url: String,
    // Media file URL for master video or audio
    media_url: String,
    // sale status of master
    sale_status: u8,
  }

  // Master metadata object that will hold all master-related metadata.
  public struct Metadata<phantom T> has key, store {
    // unique ID for master metadata
    id: UID,
    // points to Master<T> proof of ownership
    master_id: ID,
    // title of master
    title: String,
    // description of master
    description: String,
    // URL for master video or audio cover
    image_url: String,
    // Media file URL for master video or audio
    media_url: String,
    // hashtags for master
    hashtags: vector<String>,
    // original creator profile ID
    creator_profile_id: ID,
    // percentage in BP that corresponds to royalty fee for creator
    royalty_percentage_bp: u16,
    // master metadata parent object of current master metadata
    master_metadata_parent: Option<ID>,
    // origin master metadata object ID
    master_metadata_origin: Option<ID>,
    // number of expressions
    expressions: u64,
    // revenue total (synced by RECRD)
    revenue_total: u64,
    // revenue available to be paid to creator (synced by RECRD)
    // TODO: clarify if this amount is to be paid to `creator_profile_id`
    revenue_available: u64, 
    // keep track of revenue paid out
    // TODO: clarify if this amount refers to `creator_profile_id`
    revenue_paid: u64,
    // (optional) show how much revenue is pending for withdrawal
    revenue_pending: u64,
  }

  // One-time-function that runs when the contract is deployed.
  // Sets up the module publisher and display for module assets.
  fun init(otw: MASTER, ctx: &mut TxContext) {
    let publisher = package::claim(otw, ctx);

    // Create the display for `Master<T>`
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

    // Create and populate display for `Master<Video>`
    let mut master_video_display = display::new_with_fields<Master<Video>>(
      &publisher, master_keys, master_values, ctx
    );

    master_video_display.update_version();

    // Create and populate display for `Master<Sound>`
    let mut master_sound_display = display::new_with_fields<Master<Sound>>(
      &publisher, master_keys, master_values, ctx
    );

    master_sound_display.update_version();

    // Create the display for `Metadata<T>`
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

    // Create and populate display for `Metadata<Video>`
    let mut metadata_video_display = display::new_with_fields<Metadata<Video>>(
      &publisher, metadata_keys, metadata_values, ctx
    );

    metadata_video_display.update_version();

    // Create and populate display for `Metadata<Sound>`
    let mut metadata_sound_display = display::new_with_fields<Metadata<Sound>>(
      &publisher, metadata_keys, metadata_values, ctx
    );

    metadata_sound_display.update_version();

    transfer::public_transfer(publisher, tx_context::sender(ctx));
    transfer::public_transfer(master_video_display, tx_context::sender(ctx));
    transfer::public_transfer(master_sound_display, tx_context::sender(ctx));
    transfer::public_transfer(metadata_video_display, tx_context::sender(ctx));
    transfer::public_transfer(metadata_sound_display, tx_context::sender(ctx));
  }

  // === Public Functions ===

  /// Admin mints new `Master<T>` and `Metadata<T>` objects and returns `Master<T>`. 
  /// `Master<T>` is proof of ownership for the master by `creator_profile_id`
  /// and `Metadata<T>` holds all master-related metadata.
  /// Use `transfer::public_transfer(master, creator_profile_id)` to transfer
  /// the `Master<T>` proof of ownership to the creator.
  public fun new<T: drop>(
    _: &AdminCap,
    title: String,
    description: String,
    image_url: String,
    media_url: String,
    hashtags: vector<String>,
    creator_profile_id: ID,
    royalty_percentage_bp: u16,
    master_metadata_parent: Option<ID>,
    master_metadata_origin: Option<ID>,
    expressions: u64,
    revenue_total: u64,
    revenue_available: u64,
    revenue_paid: u64,
    revenue_pending: u64,
    sale_status: u8,
    ctx: &mut TxContext
  ): Master<T> {
    // Create a new UID for the master object
    let master_uid = object::new(ctx);
    let master_id = master_uid.to_inner();

    // Create a new UID for the metadata object
    let metadata_uid = object::new(ctx);
    let metadata_id = metadata_uid.to_inner();

    // Create the metadata object
    let metadata = Metadata<T> {
      id: metadata_uid,
      master_id,
      title,
      description,
      image_url,
      media_url,
      hashtags,
      creator_profile_id,
      royalty_percentage_bp,
      master_metadata_parent,
      master_metadata_origin,
      expressions,
      revenue_total, 
      revenue_available,
      revenue_paid,
      revenue_pending,
    };

    // Publicly share the metadata object. 
    transfer::public_share_object(metadata);

    // Create and return the `Master<T>` proof of ownership. 
    Master<T> {
      id: master_uid,
      metadata_ref: metadata_id,
      title,
      image_url,
      media_url,
      sale_status,
    }
  }

  /// Admin burns the `Master<T>` proof of ownership and returns the reference ID of 
  /// the `Metadata<T>` object that was associated with the `Master<T>`.
  public fun burn_master<T: drop>(_: &AdminCap, master: Master<T>): ID {
    // Deconstruct the `Master<T>` object. 
    let Master<T> {
      id, 
      metadata_ref, 
      title: _,
      image_url: _,
      media_url: _,
      sale_status: _,
    } = master;

    // Delete the `Master<T>` object and its UID.
    id.delete();

    metadata_ref
  }
  
  /// Admin burns the `Metadata<T>` object.
  public fun burn_metadata<T: drop>(_: &AdminCap, metadata: Metadata<T>) {
    // Deconstruct the `Metadata<T>` object. 
    let Metadata<T> {
      id, 
      master_id: _, 
      title: _,
      description: _,
      image_url: _,
      media_url: _,
      hashtags: _,
      creator_profile_id: _,
      royalty_percentage_bp: _,
      master_metadata_parent: _,
      master_metadata_origin: _,
      expressions: _,
      revenue_total: _,
      revenue_available: _,
      revenue_paid: _,
      revenue_pending: _,
    } = metadata;

    // Delete the `Metadata<T>` object and its UID.
    id.delete()
  }
  
  // === Master Accessors ===

  public fun id<T>(master: &Master<T>): ID {
    master.id.to_inner()
  }

  public fun metadata_ref<T>(master: &Master<T>): &ID {
    &master.metadata_ref
  }

  public fun title<T>(master: &Master<T>): &String {
    &master.title
  }

  public fun image_url<T>(master: &Master<T>): &String {
    &master.image_url
  }

  public fun media_url<T>(master: &Master<T>): &String {
    &master.media_url
  }

  public fun sale_status<T>(master: &Master<T>): u8 {
    master.sale_status
  }

  // === Metadata Accessors ===

  // Returns the master ID associated with given metadata object.
  public fun meta_master_id<T>(metadata: &Metadata<T>): &ID {
    &metadata.master_id
  }

  // Returns the title for given metadata object.
  public fun meta_title<T>(metadata: &Metadata<T>): &String {
    &metadata.title
  }

  // Returns the description for given metadata object.
  public fun meta_description<T>(metadata: &Metadata<T>): &String {
    &metadata.description
  }

  // Returns the image URL for given metadata object.
  public fun meta_image_url<T>(metadata: &Metadata<T>): &String {
    &metadata.image_url
  }

  // Returns the media URL for given metadata object.
  public fun meta_media_url<T>(metadata: &Metadata<T>): &String {
    &metadata.media_url
  }

  // Returns vector of hashtags for given metadata object.
  public fun meta_hashtags<T>(metadata: &Metadata<T>): &vector<String> {
    &metadata.hashtags
  }

  // Returns the creator's profile ID for given metadata object.
  public fun meta_creator_profile_id<T>(metadata: &Metadata<T>): &ID {
    &metadata.creator_profile_id
  }

  // Returns the royalty percentage for given metadata object.
  public fun meta_royalty_percentage_bp<T>(metadata: &Metadata<T>): u16 {
    metadata.royalty_percentage_bp
  }

  // Returns the parent metadata ID for given metadata object.
  public fun meta_parent<T>(metadata: &Metadata<T>): &Option<ID> {
    &metadata.master_metadata_parent
  }

  // Returns the origin metadata ID for given metadata object.
  public fun meta_origin<T>(metadata: &Metadata<T>): &Option<ID> {
    &metadata.master_metadata_origin
  }

  // Returns the number of expressions for given metadata object.
  public fun meta_expressions<T>(metadata: &Metadata<T>): u64 {
    metadata.expressions
  }

  // Returns the total revenue for given metadata object.
  public fun meta_revenue_total<T>(metadata: &Metadata<T>): u64 {
    metadata.revenue_total
  }

  // Returns the available revenue for given metadata object.
  public fun meta_revenue_available<T>(metadata: &Metadata<T>): u64 {
    metadata.revenue_available
  }

  // Returns the amount of revenue paid for given metadata object.
  public fun meta_revenue_paid<T>(metadata: &Metadata<T>): u64 {
    metadata.revenue_paid
  }

  // Returns the amount of revenue pending to be paid for given metadata object.
  public fun meta_revenue_pending<T>(metadata: &Metadata<T>): u64 {
    metadata.revenue_pending
  }

  // === Master Setters ===

  // Sync Master title with the title in Metadata.
  public fun sync_title<T>(master: &mut Master<T>, metadata: &Metadata<T>) {
    assert!(object::id(master) == metadata.master_id, EInvalidMetadataForMaster);
    master.title = metadata.title;
  }

  // Sync Master image URL with the image URL in Metadata.
  public fun sync_image_url<T>(master: &mut Master<T>, metadata: &Metadata<T>) {
    assert!(object::id(master) == metadata.master_id, EInvalidMetadataForMaster);
    master.image_url = metadata.image_url;
  }

  // Sync Master media URL with the media URL in Metadata.
  public fun sync_media_url<T>(master: &mut Master<T>, metadata: &Metadata<T>) {
    assert!(object::id(master) == metadata.master_id, EInvalidMetadataForMaster);
    master.media_url = metadata.media_url;
  }

  // Lists Master for sale by setting status to ON_SALE. 
  public fun list<T>(master: &mut Master<T>) {
    // Masters that are SUSPENDED cannot be set for sale. 
    assert!(master.sale_status != SUSPENDED, ESuspendedItemCannotBeListed);

    // Don't allow status update if a Receipt has been issued for master.
    assert!(master.sale_status != CLAIMED, EItemHasBeenClaimed);

    master.sale_status = ON_SALE;
  }

  // Unlists Master from market by reverting status to RETAINED. 
  public fun unlist<T>(master: &mut Master<T>) {
    // Masters that are SUSPENDED cannot revert status to retained. 
    assert!(master.sale_status != SUSPENDED, ESuspendedItemCannotBeRetained);

    // Don't allow status update if a Receipt has been issued for master.
    assert!(master.sale_status != CLAIMED, EItemHasBeenClaimed);

    master.sale_status = RETAINED;
  }

  // Admin can suspend a Master for violation.
  public fun suspend<T>(_: &AdminCap, master: &mut Master<T>) {
    master.sale_status = SUSPENDED;
  }

  // Internal status to avoid updating of Master while it's in the process of being
  // bought by a user that already has a `Receipt` for this Master.
  public(package) fun claim<T>(master: &mut Master<T>) {
    master.sale_status = CLAIMED;
  }

  // Modules can update the sale status internally.
  public(package) fun update_sale_status<T>(master: &mut Master<T>, sale_status: u8) {
    master.sale_status = sale_status;
  }

  // === Metadata Setters ===

  // Users that have (at least) BORROW access to Master can update the title 
  // for given Metadata.
  public fun set_title<T>(
    master: &Master<T>, metadata: &mut Metadata<T>, title: String
  ) {
    assert!(object::id(master) == metadata.master_id, EInvalidMetadataForMaster);
    metadata.title = title;
  }

  // Users that have (at least) BORROW access to Master can update the description  
  // for given Metadata.
  public fun set_description<T>(
    master: &Master<T>, metadata: &mut Metadata<T>, description: String
  ) {
    assert!(object::id(master) == metadata.master_id, EInvalidMetadataForMaster);
    metadata.description = description;
  }

  // Users that have (at least) BORROW access to Master can update the image URL 
  // for given Metadata.
  public fun set_image_url<T>(
    master: &Master<T>, metadata: &mut Metadata<T>, image_url: String
  ) {
    assert!(object::id(master) == metadata.master_id, EInvalidMetadataForMaster);
    metadata.image_url = image_url;
  }
  
  // Admin can update the media URL for given Metadata.
  public fun set_media_url<T>(
    _: &AdminCap, metadata: &mut Metadata<T>, media_url: String,
  ) {
    metadata.media_url = media_url;
  }

  // Admin can overwrite (replace) the hashtags for given Metadata.
  public fun set_hashtags<T>(
    _: &AdminCap, metadata: &mut Metadata<T>, hashtags: vector<String>,
  ) {
    metadata.hashtags = hashtags;
  }

  // Admin can add a hashtag to given Metadata.
  public fun add_hashtag<T>(
    _: &AdminCap, metadata: &mut Metadata<T>, hashtag: String,
  ) {
    vector::push_back(&mut metadata.hashtags, hashtag);
  }

  // Admin can remove a single hashtag from given Metadata.
  public fun remove_hashtag<T>(
    _: &AdminCap, metadata: &mut Metadata<T>, hashtag: String,
  ) {
    let (it_exists, index) = metadata.hashtags.index_of(&hashtag);
    assert!(it_exists, EHashtagDoesNotExist);
    metadata.hashtags.remove(index);
  }

  // Admin can update the royalty percentage BP for given Metadata.
  public fun set_royalty_percentage_bp<T>(
    _: &AdminCap, metadata: &mut Metadata<T>, royalty_percentage_bp: u16,
  ) {
    metadata.royalty_percentage_bp = royalty_percentage_bp;
  }

  // Admin can update the master metadata parent for given Metadata.
  public fun set_metadata_parent<T>(
    _: &AdminCap, metadata: &mut Metadata<T>, metadata_parent: Option<ID>,
  ) {
    metadata.master_metadata_parent = metadata_parent;
  }

  // Admin can update the master metadata origin for given Metadata.
  public fun set_metadata_origin<T>(
    _: &AdminCap, metadata: &mut Metadata<T>, metadata_origin: Option<ID>,
  ) {
    metadata.master_metadata_origin = metadata_origin;
  }

  /// Admin can update the expressions for given Metadata.
  public fun set_expressions<T>(
    _: &AdminCap, metadata: &mut Metadata<T>, expressions: u64,
  ) {
    metadata.expressions = expressions;
  }

  // Admin can update the revenue total for a Metadata object.
  // The new revenue total must be greater than the existing revenue total.
  // This is to ensure that the revenue total is always increasing.
  public fun set_revenue_total<T>(
    _: &AdminCap, metadata: &mut Metadata<T>, revenue_total: u64,
  ) {
    assert!(revenue_total > metadata.revenue_total, EInvalidNewRevenueTotal);
    metadata.revenue_total = revenue_total;
  }

  // Admin can update the revenue available for a Metadata object.
  public fun set_revenue_available<T>(
    _: &AdminCap, metadata: &mut Metadata<T>, revenue_available: u64,
  ) {
    metadata.revenue_available = revenue_available;
  }

  // Admin can update the revenue paid for a Metadata object.
  // The new revenue paid must be greater than the existing revenue paid.
  // This is to ensure that the revenue paid is always increasing.
  public fun set_revenue_paid<T>(
    _: &AdminCap, metadata: &mut Metadata<T>, revenue_paid: u64,
  ) {
    assert!(revenue_paid > metadata.revenue_paid, EInvalidNewRevenuePaid);
    metadata.revenue_paid = revenue_paid;
  }

  // Admin can update the revenue pending for a Metadata object.
  public fun set_revenue_pending<T>(
    _: &AdminCap, metadata: &mut Metadata<T>, revenue_pending: u64,
  ) {
    metadata.revenue_pending = revenue_pending;
  }

  // === Test only ===
  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(MASTER {}, ctx);
  }
}
