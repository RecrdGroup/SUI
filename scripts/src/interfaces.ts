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

export interface Master {
  id: string;
  type: string;
  metadataRef: string;
  title: string;
  imageUrl: string;
  mediaUrl: string;
  saleStatus: number;
}

export interface MasterMetadata {
  id: string;
  masterId: string;
  title: string;
  description: string;
  imageUrl: string;
  mediaUrl: string;
  hashtags: string[];
  creatorProfileId: string;
  royaltyPercentageBp: number;
  parent: string | null;
  origin: string | null;
  expressions: number;
  revenueTotal: number;
  revenueAvailable: number;
  revenuePaid: number;
  revenuePending: number;
}