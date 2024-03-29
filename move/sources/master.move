// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// All videos and sounds are represented as Master objects. 
/// MasterMetadata<T> will hold all master-related metadata.
/// Master<T> is the proof of ownership owned object that users 
/// will have in order to prove that they own a Master. 
module recrd::master {

  // === Imports ===

  use std::string::{String, utf8};
  use std::option::Option;
  use std::vector;
  
  use sui::object::{Self, UID, ID};
  use sui::tx_context::{Self, TxContext};
  use sui::package;
  use sui::transfer;
  use sui::display;
  use recrd::core::AdminCap;

  // === Friends ===

  // === Errors ===
  const EHashtagDoesNotExist: u64 = 1;
  const EInvalidNewRevenueTotal: u64 = 2;
  const EInvalidNewRevenuePaid: u64 = 3;
  const EInvalidSaleStatus: u64 = 4;

  // === Constants ===
  const ON_SALE: u8 = 1;
  const SUSPENDED: u8 = 2;

  // === Structs ===

  // Define an OTW to the `Publisher` object for the sender.
  struct MASTER has drop {}

  // Available types for T in Master and Metadata.
  struct Video has drop {}
  struct Sound has drop {}

  // Master object that will be the proof of ownership for the master.
  struct Master<phantom T> has key, store {
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
  struct Metadata<phantom T> has key, store {
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
      utf8(b"name"),
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
    let master_video_display = display::new_with_fields<Master<Video>>(
      &publisher, master_keys, master_values, ctx
    );

    display::update_version(&mut master_video_display);

    // Create and populate display for `Master<Sound>`
    let master_sound_display = display::new_with_fields<Master<Sound>>(
      &publisher, master_keys, master_values, ctx
    );

    display::update_version(&mut master_sound_display);

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
    let metadata_video_display = display::new_with_fields<Metadata<Video>>(
      &publisher, metadata_keys, metadata_values, ctx
    );

    display::update_version(&mut metadata_video_display);

    // Create and populate display for `Metadata<Sound>`
    let metadata_sound_display = display::new_with_fields<Metadata<Sound>>(
      &publisher, metadata_keys, metadata_values, ctx
    );

    display::update_version(&mut metadata_sound_display);

    transfer::public_transfer(publisher, tx_context::sender(ctx));
    transfer::public_transfer(master_video_display, tx_context::sender(ctx));
    transfer::public_transfer(master_sound_display, tx_context::sender(ctx));
    transfer::public_transfer(metadata_video_display, tx_context::sender(ctx));
    transfer::public_transfer(metadata_sound_display, tx_context::sender(ctx));
  }

  // === Public Functions ===

  // === Admin Functions ===

  /// Mints new `Master<T>` and `Metadata<T>` objects and returns `Master<T>`. 
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
    sale_status: u8,
    ctx: &mut TxContext,
  ): Master<T> {
    // Create a new UID for the master object
    let master_uid = object::new(ctx);
    let master_id = object::uid_to_inner(&master_uid);

    // Create a new UID for the metadata object
    let metadata_uid = object::new(ctx);
    let metadata_id = object::uid_to_inner(&metadata_uid);

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
      // TODO: update the following fields
      expressions: 0, // default to 0
      revenue_total: 0, // default to 0
      revenue_available: 0, // default to 0
      revenue_paid: 0, // default to 0
      revenue_pending: 0, // default to 0
    };

    // Publicly share the metadata object. 
    transfer::public_share_object(metadata);

    // @TODO: shouldn't we just transfer it to the profile since its an argument we pass in the new function?
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

  /// Burn the `Master<T>` proof of ownership and return the reference ID of 
  /// the `Metadata<T>` object that was associated with the `Master<T>`.
  public fun admin_burn_master<T: drop>(
    _: &AdminCap,
    master: Master<T>,
  ): ID {
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
    object::delete(id);

    metadata_ref
  }
  
  /// Burn the `Metadata<T>` object.
  public fun admin_burn_metadata<T: drop>(
    _: &AdminCap,
    metadata: Metadata<T>,
  ) {
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
    object::delete(id);
  }
  
  // --- Accessors ---

  // ~~~ Master ~~~

  public fun metadata_ref<T>(master: &Master<T>): ID {
    master.metadata_ref
  }

  public fun title<T>(master: &Master<T>): String {
    master.title
  }

  public fun image_url<T>(master: &Master<T>): String {
    master.image_url
  }

  public fun sale_status<T>(master: &Master<T>): u8 {
    master.sale_status
  }

  // ~~~ Metadata ~~~

  public fun master_id<T>(metadata: &Metadata<T>): ID {
    metadata.master_id
  }

  public fun description<T>(metadata: &Metadata<T>): String {
    metadata.description
  }

  public fun hashtags<T>(metadata: &Metadata<T>): vector<String> {
    metadata.hashtags
  }

  public fun creator_profile_id<T>(metadata: &Metadata<T>): ID {
    metadata.creator_profile_id
  }

  public fun royalty_percentage_bp<T>(metadata: &Metadata<T>): u16 {
    metadata.royalty_percentage_bp
  }

  public fun master_metadata_parent<T>(metadata: &Metadata<T>): Option<ID> {
    metadata.master_metadata_parent
  }

  public fun master_metadata_origin<T>(metadata: &Metadata<T>): Option<ID> {
    metadata.master_metadata_origin
  }

  public fun expressions<T>(metadata: &Metadata<T>): u64 {
    metadata.expressions
  }

  public fun revenue_total<T>(metadata: &Metadata<T>): u64 {
    metadata.revenue_total
  }

  public fun revenue_available<T>(metadata: &Metadata<T>): u64 {
    metadata.revenue_available
  }

  public fun revenue_paid<T>(metadata: &Metadata<T>): u64 {
    metadata.revenue_paid
  }

  public fun revenue_pending<T>(metadata: &Metadata<T>): u64 {
    metadata.revenue_pending
  }

  // --- Setters & Mutations ---
  // @TODO: to check access level for these functions

  // ~~~ Master ~~~

  // @TODO: probbaly should be removed, the metadata ref should always remain the same.
  // Admin can update the metadata reference for a Master object.
  // public fun set_metadata_ref<T>(
  //   _: &AdminCap,
  //   master: &mut Master<T>,
  //   metadata_ref: ID,
  // ) {
  //   master.metadata_ref = metadata_ref;
  // }

  // Anyone with access to the Master can update the title.
  public fun set_title<T>(
    master: &mut Master<T>,
    title: String,
  ) {
    master.title = title;
  }

  // Anyone with access to the Master can update the image URL.
  public fun set_image_url<T>(
    master: &mut Master<T>,
    image_url: String,
  ) {
    master.image_url = image_url;
  }

  // Admin can update the sale status for a Master object.
  public fun set_sale_status<T>(
    _: &AdminCap,
    master: &mut Master<T>,
    sale_status: u8,
  ) {
    assert!(sale_status == ON_SALE || sale_status == SUSPENDED, EInvalidSaleStatus);
    master.sale_status = sale_status;
  }

  // ~~~ Metadata ~~~

  // @TODO: probbaly should be removed, the master ref should always remain the same.
  // Admin can update the master ID for a Metadata object.
  // public fun set_master_id<T>(
  //   _: &AdminCap,
  //   metadata: &mut Metadata<T>,
  //   master_id: ID,
  // ) {
  //   metadata.master_id = master_id;
  // }

  // Admin can update the description for a Metadata object.
  public fun set_description<T>(
    _: &AdminCap,
    metadata: &mut Metadata<T>,
    description: String,
  ) {
    metadata.description = description;
  }

  // Admin can overwrite the hashtags for a Metadata object.
  // This will replace the existing hashtags.
  public fun set_hashtags<T>(
    _: &AdminCap,
    metadata: &mut Metadata<T>,
    hashtags: vector<String>,
  ) {
    metadata.hashtags = hashtags;
  }

  // Admin can add a hashtag to the Metadata object.
  public fun add_hashtag<T>(
    _: &AdminCap,
    metadata: &mut Metadata<T>,
    hashtag: String,
  ) {
    vector::push_back(&mut metadata.hashtags, hashtag);
  }

  // Admin can remove a single hashtag from the Metadata object.
  public fun remove_hashtag<T>(
    _: &AdminCap,
    metadata: &mut Metadata<T>,
    hashtag: String,
  ) {
    let (exists, index) = vector::index_of(&metadata.hashtags, &hashtag);
    assert!(exists, EHashtagDoesNotExist);
    vector::remove(&mut metadata.hashtags, index);
  }

  // Admin can update the creator profile ID for a Metadata object.
  public fun set_creator_profile_id<T>(
    _: &AdminCap,
    metadata: &mut Metadata<T>,
    creator_profile_id: ID,
  ) {
    metadata.creator_profile_id = creator_profile_id;
  }

  // Admin can update the royalty percentage BP for a Metadata object.
  public fun set_royalty_percentage_bp<T>(
    _: &AdminCap,
    metadata: &mut Metadata<T>,
    royalty_percentage_bp: u16,
  ) {
    metadata.royalty_percentage_bp = royalty_percentage_bp;
  }

  // Admin can update the master metadata parent for a Metadata object.
  public fun set_master_metadata_parent<T>(
    _: &AdminCap,
    metadata: &mut Metadata<T>,
    master_metadata_parent: Option<ID>,
  ) {
    metadata.master_metadata_parent = master_metadata_parent;
  }

  // Admin can update the master metadata origin for a Metadata object.
  public fun set_master_metadata_origin<T>(
    _: &AdminCap,
    metadata: &mut Metadata<T>,
    master_metadata_origin: Option<ID>,
  ) {
    metadata.master_metadata_origin = master_metadata_origin;
  }

  // @TODO: Can expressions reduce? If not, should assert that the new value is greater than the current value.
  // Admin can update the expressions for a Metadata object.
  public fun set_expressions<T>(
    _: &AdminCap,
    metadata: &mut Metadata<T>,
    expressions: u64,
  ) {
    metadata.expressions = expressions;
  }

  // Admin can update the revenue total for a Metadata object.
  public fun set_revenue_total<T>(
    _: &AdminCap,
    metadata: &mut Metadata<T>,
    revenue_total: u64,
  ) {
    assert!(revenue_total > metadata.revenue_total, EInvalidNewRevenueTotal);
    metadata.revenue_total = revenue_total;
  }

  // Admin can update the revenue available for a Metadata object.
  public fun set_revenue_available<T>(
    _: &AdminCap,
    metadata: &mut Metadata<T>,
    revenue_available: u64,
  ) {
    metadata.revenue_available = revenue_available;
  }

  // Admin can update the revenue paid for a Metadata object.
  public fun set_revenue_paid<T>(
    _: &AdminCap,
    metadata: &mut Metadata<T>,
    revenue_paid: u64,
  ) {
    assert!(revenue_paid > metadata.revenue_paid, EInvalidNewRevenuePaid);
    metadata.revenue_paid = revenue_paid;
  }

  // Admin can update the revenue pending for a Metadata object.
  public fun set_revenue_pending<T>(
    _: &AdminCap,
    metadata: &mut Metadata<T>,
    revenue_pending: u64,
  ) {
    metadata.revenue_pending = revenue_pending;
  }

  // === Test only ===
  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(MASTER {}, ctx);
  }
}
