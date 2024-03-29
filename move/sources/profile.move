// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// All users on `RECRD app will have a `Profile` object (registered and anonymous).
/// The user `Profile` object will include user related metadata, such as:
/// - User ID (we are considering to hash this information)
/// - Username (for registered users).
/// - Other metadata for user (TODO: What other meta do we want to store on-chain for user profile?)
/// - DAW related fields:
/// -- Static field for total time watched in seconds.
/// -- 1-1 dynamic field for every video the user has watched (TODO: to be considered)
module recrd::profile {

  // === Imports ===

  use sui::tx_context::{Self, TxContext};
  use sui::object::{Self, UID, ID};
  use sui::transfer::{Self, Receiving};
  use sui::table::{Self, Table};

  use std::string::{String};

  use recrd::core::AdminCap;
  use recrd::master::{Self, Master};
  use recrd::receipt::{Self, Receipt};

  // === Friends ===

  // === Errors ===
  const ENewValueShouldBeHigher: u64 = 0;
  const EInvalidSaleStatus: u64 = 1;
  const EInvalidAccessRights: u64 = 2;
  const EInvalidObject: u64 = 3;
  const EInvalidAccessOption: u64 = 4;
  const ENoEntryFound: u64 = 5;

  // === Constants ===

  // Allows to borrow with a hot potato, so it has to be returned
  const BORROW_ACCESS: u8 = 0; 
  // Allows to remove the item from the Profile without restrictions
  const REMOVE_ACCESS: u8 = 1; 

  const ON_SALE: u8 = 1;
  // const SUSPENDED: u8 = 2;

  // === Structs ===

  /// A Promise hot potato to ensure Master is returned to profile when borrowed.
  struct Promise {
    master_id: ID,
    profile: address
  }

  struct Profile has key, store {
    // unique id for the profile object
    id: UID,
    // user ID derived from RECRD app db
    user_id: String, 
    // type pending to decide the hashing approach
    username: String,
    // Keep a record of each user's address + RECRD address
	  // in the format of a pair <address, REMOVE_ACCESS | BORROW_ACCESS>
    authorizations: Table<address, u8>,
    // total time the user has spent on watching videos
    watch_time: u64, // in seconds
    // (TBD) dynamic fields for every video watched
    videos_watched: u64,
	  // Number of adverts seen
	  adverts_watched: u64,
    // Number of followers
	  number_of_followers: u64,
    // Number of users followed
	  number_of_following: u64,
    // Total ad revenue earned
  	ad_revenue: u64,
    // Total commission revenue earned
	  commission_revenue: u64
  }

  // === Public Functions ===

  /// Creates a new `Profile` object and makes it a shared object.
  public fun create_and_share(
    _: &AdminCap, user_id: String, username: String, ctx: &mut TxContext,
  ) {
    transfer::public_share_object(
      Profile {
        id: object::new(ctx),
        user_id,
        username,
        authorizations: table::new(ctx),
        watch_time: 0, // initial watch time is zero
        videos_watched: 0,
        adverts_watched: 0,
        number_of_followers: 0,
        number_of_following: 0,
        ad_revenue: 0,
        commission_revenue: 0,
      }
    );
  }

  /// Admin authorizes user with level of access to the profile.
  public fun authorize(
    _: &AdminCap, self: &mut Profile, user: address, access: u8, _ctx: &mut TxContext
  ) {
    assert!(access == REMOVE_ACCESS || access == BORROW_ACCESS, EInvalidAccessOption);
    // @TODO: decide if only admin can authorize or users of access x can also authorize with access x
    // let sender_access = *table::borrow(&self.authorizations, tx_context::sender(ctx));
    // assert!(sender_access == access, EInvalidAccessRights);
    table::add(&mut self.authorizations, user, access);
  }

  #[allow(lint(self_transfer))]
  /// Receives Master<T> iff sender is in the authorizations table with REMOVE_ACCESS.
  public fun receive_master<T: key + store>(
    self: &mut Profile, master: Receiving<Master<T>>, ctx: &mut TxContext
  ): Master<T> {
    assert!(
      *table::borrow(&self.authorizations, tx_context::sender(ctx)) == REMOVE_ACCESS,
      EInvalidAccessRights
    );

    receive_master_(self, master)
  }

  /// Borrows Master<T> temporarily with a Promise to return it back. 
  public fun borrow_master<T: key + store>(
    self: &mut Profile, master: Receiving<Master<T>>, ctx: &mut TxContext
  ): (Master<T>, Promise) {
    assert!(
      *table::borrow(&self.authorizations, tx_context::sender(ctx)) == BORROW_ACCESS, 
      EInvalidAccessRights
    );

    let master = receive_master_(self, master);

    let promise = Promise { 
      master_id: object::id(&master),
      profile: object::id_address(self)
    };

    (master, promise)
  }

  // Returns the master back to the profile
  public fun return_master<T>(master: Master<T>, promise: Promise) {
    let Promise {master_id, profile} = promise;
    assert!(object::id(&master) == master_id, EInvalidObject);
    transfer::public_transfer(master, profile);
  }

  /// Buys a Master<T> object from a seller profile and transfers it to the 
  /// buyer profile after redeeming the receipt.
  public fun buy<T: key + store>(
    seller_profile: &mut Profile,
    master: Receiving<Master<T>>,
    buyer_profile: &mut Profile,
    receipt: Receiving<Receipt>,
  ) {
    // Receive the receipt from the buyer profile
    let receipt = receipt::receive(&mut buyer_profile.id, receipt);

    // Burn the receipt to get the master id and the user profile
    let (master_id, user_profile) = receipt::burn(receipt);

    // Receive the master from the seller profile
    let master = receive_master_(seller_profile, master);

    // Validate the master id from the receipt and the master object
    assert!(object::id(&master) == master_id, EInvalidObject);

    // Transfer the master to the buyer profile
    transfer::public_transfer(master, user_profile);
  }


  // === Update functions ===

  // @TODO: (note) Assumption that the user id & username do not change 

  public fun update_watch_time(
    _: &AdminCap, self: &mut Profile, new_watch_time: u64,
  ) {
    // Make sure the watch_time is greater than the current watch_time.
    assert!(new_watch_time > self.watch_time, ENewValueShouldBeHigher);

    self.watch_time = new_watch_time;
  }

  public fun update_videos_watched(
    _: &AdminCap, self: &mut Profile, new_videos_watched: u64,
  ) {
    assert!(new_videos_watched > self.videos_watched, ENewValueShouldBeHigher);
    self.videos_watched = new_videos_watched;
  }

  public fun update_adverts_watched(
    _: &AdminCap, self: &mut Profile, new_adverts_watched: u64,
  ) {
    assert!(new_adverts_watched > self.adverts_watched, ENewValueShouldBeHigher);
    self.adverts_watched = new_adverts_watched;
  }

  public fun update_number_of_followers(
    _: &AdminCap,
    self: &mut Profile,
    new_number_of_followers: u64,
  ) {
    self.number_of_followers = new_number_of_followers;
  }

  public fun update_number_of_following(
    _: &AdminCap, self: &mut Profile, new_number_of_following: u64,
  ) {
    self.number_of_following = new_number_of_following;
  }

  public fun update_ad_revenue(
    _: &AdminCap, self: &mut Profile, new_ad_revenue: u64,
  ) {
    assert!(new_ad_revenue > self.ad_revenue, ENewValueShouldBeHigher);
    self.ad_revenue = new_ad_revenue;
  }

  public fun update_commission_revenue(
    _: &AdminCap, self: &mut Profile, new_commission_revenue: u64,
  ) {
    assert!(new_commission_revenue > self.commission_revenue, ENewValueShouldBeHigher);
    self.commission_revenue = new_commission_revenue;
  }

  // === Accessors ===

  public fun user_id(self: &Profile): String {
    self.user_id
  }

  public fun username(self: &Profile): String {
    self.username
  }

  public fun access_rights(self: &Profile, user: address): u8 {
    assert!(table::contains(&self.authorizations, user), ENoEntryFound);
    *table::borrow(&self.authorizations, user)
  }

  public fun watch_time(self: &Profile): u64 {
    self.watch_time
  }

  public fun videos_watched(self: &Profile): u64 {
    self.videos_watched
  }

  public fun adverts_watched(self: &Profile): u64 {
    self.adverts_watched
  }
  
  public fun number_of_followers(self: &Profile): u64 {
    self.number_of_followers
  }

  public fun number_of_following(self: &Profile): u64 {
    self.number_of_following
  }

  public fun ad_revenue(self: &Profile): u64 {
    self.ad_revenue
  }
  
  public fun commission_revenue(self: &Profile): u64 {
    self.commission_revenue
  }

  // === Private Functions ===
  fun receive_master_<T: key + store>(
    self: &mut Profile, master_to_receive: Receiving<Master<T>>
  ): Master<T> {
    let master = transfer::public_receive(&mut self.id, master_to_receive);
    assert!(master::sale_status(&master) != ON_SALE, EInvalidSaleStatus);
    master
  }

  // === Test Only ===
  #[test_only]
  public fun create_for_testing(user_id: String, username: String, ctx: &mut TxContext): Profile {
    Profile {
      id: object::new(ctx),
      user_id,
      username,
      authorizations: table::new(ctx),
      watch_time: 0, // initial watch time is zero
      videos_watched: 0,
      adverts_watched: 0,
      number_of_followers: 0,
      number_of_following: 0,
      ad_revenue: 0,
      commission_revenue: 0,
    }
  }

  #[test_only]
  public fun burn_for_testing(profile: Profile) {
     let Profile {
      id,
      user_id: _,
      username: _,
      authorizations,
      watch_time: _, // initial watch time is zero
      videos_watched: _,
      adverts_watched: _,
      number_of_followers: _,
      number_of_following: _,
      ad_revenue: _,
      commission_revenue: _,
    } = profile;

    object::delete(id);
    table::drop(authorizations);
  }

}