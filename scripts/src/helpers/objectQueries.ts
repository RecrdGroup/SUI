// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { SuiClient } from '@mysten/sui.js/client';

/// Returns all objects of a given type owned by an address.
export const getObjectsByType = async (
  { address, objectType }: { address: string, objectType: string },
  client: SuiClient,
  nextCursor: string = ''
): Promise<any> => {

  // return an empty array for non-address.
  if (!address) return Promise.resolve([]);

  let getObjectsQuery = {
    filter: { StructType: objectType },
    owner: address,
    options: { 
      showContent: true, 
      showOwner: true, 
      showType: true 
    },
  };

  if (nextCursor) Object.assign(getObjectsQuery, { cursor: nextCursor });

  return client.getOwnedObjects(getObjectsQuery).then(async (res) => {
    let objectsArray = res.data.map((item: any) => item.data);
    let nextPageData: any[] = [];

    if (res.hasNextPage && typeof res?.nextCursor === 'string') {
        nextPageData = await getObjectsByType({address, objectType}, client, res.nextCursor);
    }
    
    return objectsArray.concat(nextPageData);
  }).catch((error) => {
    console.error("Error fetching owned objects:", error);
    throw error;
  });
};