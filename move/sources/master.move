// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// All videos and sounds are represented as Master objects. 
/// MasterMetadata<T> will hold all master-related metadata.
/// Master<T> is the proof of ownership owned object that users 
/// will have in order to prove that they own a Master. 
module recrd::master {

  // === Imports ===
  
  use sui::object::{Self, UID, ID};
  use std::string::{String, utf8};
  use sui::tx_context::{Self, TxContext};
  use sui::package;
  use sui::transfer;
  use sui::display;
  use std::option::{Option};
  use recrd::core::{AdminCap};

  // === Friends ===

  // === Errors ===

  // === Constants ===

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
    // URL for master video or audio (needed for display)
    image_url: String,
    // whether the master is currently on sale
    on_sale: bool,
  }

  // Master metadata object that will hold all master-related metadata.
  struct Metadata<phantom T> has key, store {
    // unique ID for master metadata
    id: UID,
    // points to Master<T> proof of ownership
    master_id: ID,
    // description of master
    description: String,
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
    expressions: u64, // TODO: clarify the purpose of this field
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
      utf8(b"image_url"),
      utf8(b"metadata_ref"),
      utf8(b"description"),
    ];

    let master_values = vector[
      utf8(b"{title}"),
      utf8(b"{image_url}"),
      utf8(b"{metadata_ref}"),
      utf8(b"Recrd is a best in class social media application empowering creators."),
    ];

    let master_display = display::new_with_fields<Master<Video>>(
      &publisher, master_keys, master_values, ctx
    );

    display::update_version(&mut master_display);

    // Create the display for `Metadata<T>`
    let metadata_keys = vector[
      utf8(b"description"),
      utf8(b"hashtags"),
      utf8(b"creator_profile_id"),
      utf8(b"master_metadata_parent"),
      utf8(b"master_metadata_origin"),
      utf8(b"expressions"),
    ];

    let metadata_values = vector[
      utf8(b"{description}"),
      utf8(b"{hashtags}"),
      utf8(b"{creator_profile_id}"),
      utf8(b"{master_metadata_parent}"),
      utf8(b"{master_metadata_origin}"),
      utf8(b"{expressions}"),
    ];

    let metadata_display = display::new_with_fields<Metadata<Video>>(
      &publisher, metadata_keys, metadata_values, ctx
    );

    display::update_version(&mut metadata_display);

    transfer::public_transfer(publisher, tx_context::sender(ctx));
    transfer::public_transfer(master_display, tx_context::sender(ctx));
    transfer::public_transfer(metadata_display, tx_context::sender(ctx));
  }

  // === Public Functions ===

  // === Admin Functions ===

  // Mints new Master and Metadata objects and returns the proof of ownership 
  // for the `Master<T>`.
  public fun new<T: drop>(
    _: &AdminCap,
    title: String,
    image_url: String,
    description: String,
    hashtags: vector<String>,
    creator_profile_id: ID,
    royalty_percentage_bp: u16,
    master_metadata_parent: Option<ID>,
    master_metadata_origin: Option<ID>,
    on_sale: bool,
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
      description,
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

    // Create and return the `Master<T>` proof of ownership. 
    Master<T> {
      id: master_uid,
      metadata_ref: metadata_id,
      title,
      image_url,
      on_sale,
    }
  }

  // Burn the `Master<T>` proof of ownership. 
  public fun admin_burn_master<T: drop>(
    _: &AdminCap,
    master: Master<T>,
  ) {
    // Deconstruct the `Master<T>` object. 
    let Master<T> {
      id, 
      metadata_ref: _, 
      title: _,
      image_url: _,
      on_sale: _,
    } = master;

    // Delete the `Master<T>` object and its UID.
    object::delete(id);
  }
  
  // Burn the `Metadata<T>` object.
  public fun admin_burn_metadata<T: drop>(
    _: &AdminCap,
    metadata: Metadata<T>,
  ) {
    // Deconstruct the `Metadata<T>` object. 
    let Metadata<T> {
      id, 
      master_id: _, 
      description: _,
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
}
