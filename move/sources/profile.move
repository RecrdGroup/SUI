// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
#[allow(unused_const)]
/// All users on `RECRD app will have a `Profile` object (registered and anonymous).
/// The user `Profile` object will include user related metadata. 
/// Each user will also receive a unique capability object under their accounts in 
/// order to maintain a two-way relationship between all the user accounts and 
/// their profiles.
module recrd::profile {

  // === Imports ===
  use sui::transfer::{Receiving};
  use sui::table::{Self, Table};
  use std::string::{String};

  // === Package dependencies ===
  use recrd::core::AdminCap;
  use recrd::master::{Self, Master};
  use recrd::receipt::{Self, Receipt};

  // === Custom Receivers ===
  use fun new_cap_ as ID.new_cap_;

  // === Errors ===
  const ENewValueShouldBeHigher: u64 = 0;
  const EInvalidSaleStatus: u64 = 1;
  const EInvalidAccessRights: u64 = 2;
  const EInvalidObject: u64 = 3;
  const EAccessLevelOutOfRange: u64 = 4;
  const ENotAuthorized: u64 = 5;
  const EAccessLevelOutOfBounds: u64 = 6;
  const EMasterNotOnSale: u64 = 7;

  // === Constants ===

  // Levelling will be facilitated in the range [0, 255] and
  // the default levels will be set to mid ranges so that we can 
  // increase and decrease level of access by 10.
  const DEFAULT_ACCESS: u8 = 100;
  // Allows to borrow with a hot potato, so it has to be returned
  const BORROW_ACCESS: u8 = 110; 
  // Allows access for updating Profile (i.e. custodial wallets managed by RECRD)
  const UPDATE_ACCESS: u8 = 120;
  // Allows to remove the item from the Profile without restrictions
  const REMOVE_ACCESS: u8 = 150;
  // Required level of access for admin gated access
  const ADMIN_ACCESS: u8 = 200;

  // Stale state is when the master is not on sale
  const STALE: u8 = 0;
  // On sale state is when the master is on sale
  const ON_SALE: u8 = 1;
  // Admin enforced state when rules are not met
  const SUSPENDED: u8 = 3;

  // === Structs ===

  /// A Promise hot potato to ensure Master is returned to profile when borrowed.
  public struct Promise {
    master_id: ID,
    profile: address
  }

  public struct Profile has key, store {
    // unique id for the profile object
    id: UID,
    // user ID derived from RECRD app db
    user_id: String, 
    // type pending to decide the hashing approach
    username: String,
    // Keep a record of each user's address + RECRD address
	  // in the format of a pair <address, Access Level [0,250]>
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

  // Profile identity for users to link their account to their Profile. 
  public struct Identity has key, store {
    id: UID,
    profile: ID,
  }

  // === Public Functions ===

  /// Creates a new `Profile` object and a new `Identity` for the user.
  /// `Profile` will be publicly shared and `Identity` will be returned, so 
  /// that it can be transferred via PTBs.
  public fun new(
    _: &AdminCap, user_id: String, username: String, ctx: &mut TxContext,
  ): Identity {
    let profile = Profile {
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
    };

    let profile_id = profile.id.to_inner();

    // Make `Profile` a shared object. 
    transfer::public_share_object(profile);

    // Give the user borrow access by default.
    profile_id.new_cap_(ctx)
  }

  /// Admin can send more Identitys to users that have existing Profile. 
  public fun new_cap(
    _: &AdminCap, profile: &Profile, ctx: &mut TxContext
  ): Identity {
    profile.id.to_inner().new_cap_(ctx)
  }

  /// Admin authorizes user with level of access to the profile.
  public fun authorize(
    _: &AdminCap, self: &mut Profile, addr: address, access: u8
  ) {
    // Users access level should be in the range of (0, 200)
    assert!(access > 0 && access <= 250, EAccessLevelOutOfRange);
    
    self.authorizations.add(addr, access);
  }

  /// Admin removes user's access to the profile.
  public fun deauthorize(
    _: &AdminCap, self: &mut Profile, user: address
  ) {
    self.authorizations.remove(user);
  }

  /// Admin can receive any `T` object from `Profile`.
  public fun admin_receive<T: key + store>(
    _:&AdminCap, self: &mut Profile, object: Receiving<T>
  ): T {
    transfer::public_receive<T>(&mut self.id, object)
  }

  /// Borrows Master<T> temporarily with a Promise to return it back. 
  public fun borrow_master<T: drop>(
    self: &mut Profile, master: Receiving<Master<T>>, ctx: &mut TxContext
  ): (Master<T>, Promise) {
    // Check whether sender exists in authorization table. 
    assert!(
      self.authorizations.contains(ctx.sender()),
      ENotAuthorized
    );

    // Users that have access above the BORROW_ACCESS threshold can borrow the master
    assert!(
      *self.authorizations.borrow(ctx.sender()) >= BORROW_ACCESS,
      EInvalidAccessRights
    );

    let master = self.receive_master_<T>(master);

    let promise = Promise { 
      master_id: object::id(&master),
      profile: object::id_address(self)
    };

    (master, promise)
  }

  /// Returns the master back to the profile
  public fun return_master<T: drop>(master: Master<T>, promise: Promise) {
    let Promise {master_id, profile} = promise;
    assert!(object::id(&master) == master_id, EInvalidObject);
    transfer::public_transfer(master, profile);
  }

  /// Buys a Master<T> object from a seller profile and transfers it to the 
  /// buyer profile after redeeming the receipt.
  public fun buy<T: drop>(
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
    let mut master = seller_profile.receive_master_<T>(master);

    // Validate the master id from the receipt and the master object
    assert!(object::id(&master) == master_id, EInvalidObject);

    // Only masters with ON_SALE status can be bought
    assert!(master::sale_status<T>(&master) == ON_SALE, EMasterNotOnSale);

    // Update the sale status of the master object to STALE
    master::update_sale_status<T>(&mut master, STALE);

    // Transfer the master to the buyer profile
    transfer::public_transfer(master, user_profile);
  }


  // === Update functions ===

  // Admin can update the user ID. 
  public fun update_user_id(_: &AdminCap, self: &mut Profile, new_user_id: String) {
    self.user_id = new_user_id;
  }

  // Authorized addresses can update username.
  public fun update_username(self: &mut Profile, new_username: String, ctx: &mut TxContext) {
    // Only addresses in the authorizations table can update.
    assert!(self.authorizations.contains(ctx.sender()), ENotAuthorized);
    self.username = new_username
  }

  // Authorized addresses can update watch time.
  public fun update_watch_time(
    self: &mut Profile, new_watch_time: u64, ctx: &mut TxContext
  ) {
    // Only addresses in the authorizations table can update.
    assert!(self.authorizations.contains(ctx.sender()), ENotAuthorized);

    // Make sure the watch_time is greater than the current watch_time.
    assert!(new_watch_time > self.watch_time, ENewValueShouldBeHigher);

    self.watch_time = new_watch_time;
  }

  // Authorized addresses can update number of videos watched. 
  public fun update_videos_watched(
    self: &mut Profile, new_videos_watched: u64, ctx: &mut TxContext
  ) {
    // Only addresses in the authorizations table can update.
    assert!(self.authorizations.contains(ctx.sender()), ENotAuthorized);

    // New number of videos watched should greater than current.
    assert!(new_videos_watched > self.videos_watched, ENewValueShouldBeHigher);

    self.videos_watched = new_videos_watched;
  }

  // Authorized addresses can update number of adverts watched. 
  public fun update_adverts_watched(
    self: &mut Profile, new_adverts_watched: u64, ctx: &mut TxContext
  ) {
    // Only addresses in the authorizations table can update.
    assert!(self.authorizations.contains(ctx.sender()), ENotAuthorized);

    // New number of adverts watched should greater than current. 
    assert!(new_adverts_watched > self.adverts_watched, ENewValueShouldBeHigher);

    self.adverts_watched = new_adverts_watched;
  }

  // Authorized addresses can update number of followers.
  public fun update_number_of_followers( 
    self: &mut Profile, new_number_of_followers: u64, ctx: &mut TxContext
  ) {
    // Only addresses in the authorizations table can update.
    assert!(self.authorizations.contains(ctx.sender()), ENotAuthorized);

    self.number_of_followers = new_number_of_followers;
  }

  // Authorized addresses can update number of following users.
  public fun update_number_of_following(
    self: &mut Profile, new_number_of_following: u64, ctx: &mut TxContext
  ) {
    // Only addresses in the authorizations table can update.
    assert!(self.authorizations.contains(ctx.sender()), ENotAuthorized);

    self.number_of_following = new_number_of_following;
  }

  // Admin can update the ad revenue.
  public fun update_ad_revenue(
    _: &AdminCap, self: &mut Profile, new_ad_revenue: u64,
  ) {
    assert!(new_ad_revenue > self.ad_revenue, ENewValueShouldBeHigher);
    self.ad_revenue = new_ad_revenue;
  }

  // Admin can update the commission revenue.
  public fun update_commission_revenue(
    _: &AdminCap, self: &mut Profile, new_commission_revenue: u64,
  ) {
    assert!(new_commission_revenue > self.commission_revenue, ENewValueShouldBeHigher);
    self.commission_revenue = new_commission_revenue;
  }

  // Admin can update the authorization table.
  public fun update_authorization(
    _: &AdminCap, self: &mut Profile, addr: address, new_access: u8
  ) {
    update_authorization_(self, addr, new_access);
  }

  // === Accessors ===

  // Returns the user ID.
  public fun user_id(self: &Profile): String {
    self.user_id
  }

  // Returns the username.
  public fun username(self: &Profile): String {
    self.username
  }

  // Returns the level of access for given address.
  public fun access_rights(self: &Profile, user: address): u8 {
    // First checks whether the address exists in the authorizations table.
    assert!(self.authorizations.contains(user), ENotAuthorized);
    *self.authorizations.borrow(user)
  }

  // Updates the watch time for given profile.
  public fun watch_time(self: &Profile): u64 {
    self.watch_time
  }

  // Updates the number of videos watched for given profile.
  public fun videos_watched(self: &Profile): u64 {
    self.videos_watched
  }

  // Updates the number of adverts watched for given profile.
  public fun adverts_watched(self: &Profile): u64 {
    self.adverts_watched
  }
  
  // Updates the number of followers for given profile.
  public fun number_of_followers(self: &Profile): u64 {
    self.number_of_followers
  }

  // Updates the number users given profile is following.
  public fun number_of_following(self: &Profile): u64 {
    self.number_of_following
  }

  // Updates the ad revenue for given profile.
  public fun ad_revenue(self: &Profile): u64 {
    self.ad_revenue
  }
  
  // Updates the commission revenue for given profile.
  public fun commission_revenue(self: &Profile): u64 {
    self.commission_revenue
  }

  // === Private Functions ===

  /// Receives `Master<T>` from `Profile`
  fun receive_master_<T: drop>(
    self: &mut Profile, master_to_receive: Receiving<Master<T>>
  ): Master<T> {
    transfer::public_receive<Master<T>>(&mut self.id, master_to_receive)
  }

  /// Creates and returns a new Identity object. 
  fun new_cap_(profile_id: ID, ctx: &mut TxContext): Identity {
    Identity {
      id: object::new(ctx),
      profile: profile_id,
    }
  }

  /// Updates the access level of given address in the `Profile` authorization table.
  fun update_authorization_(self: &mut Profile, addr: address, new_access: u8) {
    // Make sure the new access level is within the allowed range. 
    assert!(new_access >= 0 && new_access <= 250, EAccessLevelOutOfRange);

    // Check whether given address exists in authorization table. 
    assert!(self.authorizations.contains(addr), ENotAuthorized);

    let current_access = self.authorizations.borrow_mut(addr);
    *current_access = new_access;
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

    id.delete();
    authorizations.drop();
  }

}