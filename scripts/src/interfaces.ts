// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

export interface Profile {
  id: string;
  userId: string;
  username: string;
  authorizations: Map<string, number>;
  watchTime: number;
  videosWatched: number;
  advertsWatched: number;
  numberOfFollowers: number;
  numberOfFollowing: number;
  adRevenue: number;
  commissionRevenue: number;
}

export interface AuthorizationDynamicFieldContent {
  dataType: 'moveObject' | 'package';
  fields?: {
    name: string;
    value: number;
  };
}