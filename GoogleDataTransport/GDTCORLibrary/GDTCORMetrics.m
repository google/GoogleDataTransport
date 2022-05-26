// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetrics.h"

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORStorageSizeBytes.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCOREventMetricsCounter.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsMetadata.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORStorageMetadata.h"

@interface GDTCORMetrics ()

/// The end of the time window over which the metrics were collected.
@property(nonatomic, readonly) NSDate *collectionEndDate;
/// The number of bytes the event cache was consuming in storage.
@property(nonatomic, readonly) GDTCORStorageSizeBytes currentCacheSize;
/// The maximum number of bytes that the event cache is allowed to grow.
@property(nonatomic, readonly) GDTCORStorageSizeBytes maxCacheSize;
/// The bundle ID associated with the metrics being collected.
@property(nonatomic, readonly) NSString *bundleID;

@end

@implementation GDTCORMetrics

- (instancetype)initWithCollectionStartDate:(NSDate *)collectionStartDate
                          collectionEndDate:(NSDate *)collectionEndDate
                        droppedEventCounter:(GDTCOREventMetricsCounter *)droppedEventCounter
                           currentCacheSize:(GDTCORStorageSizeBytes)currentCacheSize
                               maxCacheSize:(GDTCORStorageSizeBytes)maxCacheSize
                                   bundleID:(NSString *)bundleID {
  self = [super init];
  if (self) {
    _collectionStartDate = collectionStartDate;
    _collectionEndDate = collectionEndDate;
    _droppedEventCounter = droppedEventCounter;
    _currentCacheSize = currentCacheSize;
    _maxCacheSize = maxCacheSize;
    _bundleID = bundleID;
  }
  return self;
}

+ (instancetype)metricsWithMetricsMetadata:(GDTCORMetricsMetadata *)metricsMetadata
                           storageMetadata:(GDTCORStorageMetadata *)storageMetadata {
  NSParameterAssert(metricsMetadata);
  NSParameterAssert(storageMetadata);
  // The window of collection ends at the time of creating the metrics object.
  NSDate *collectionEndDate = [NSDate date];
  // The main bundle ID is associated with the created metrics.
  NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier] ?: @"";

  return [[GDTCORMetrics alloc] initWithCollectionStartDate:metricsMetadata.collectionStartDate
                                          collectionEndDate:collectionEndDate
                                        droppedEventCounter:metricsMetadata.droppedEventCounter
                                           currentCacheSize:storageMetadata.currentCacheSize
                                               maxCacheSize:storageMetadata.maxCacheSize
                                                   bundleID:bundleID];
}

- (nonnull NSData *)transportBytes {
  // TODO(ncooke3): Implement.
  return [NSData data];
}

@end
