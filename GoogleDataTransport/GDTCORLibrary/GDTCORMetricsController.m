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

#import <Foundation/Foundation.h>

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsController.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORConsoleLogger.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORRegistrar.h"
#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORStorageProtocol.h"

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCOREventMetricsCounter.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORFlatFileStorage+Promises.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetrics.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsMetadata.h"

@interface GDTCORMetricsController ()
/// The underlying storage object where metrics are stored.
@property(nonatomic) id<GDTCORStoragePromiseProtocol> storage;

@end

@implementation GDTCORMetricsController

+ (void)load {
  [[GDTCORRegistrar sharedInstance] registerMetricsController:[self sharedInstance]
                                                       target:kGDTCORTargetCSH];
  [[GDTCORRegistrar sharedInstance] registerMetricsController:[self sharedInstance]
                                                       target:kGDTCORTargetFLL];
}

+ (instancetype)sharedInstance {
  static id sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] initWithStorage:[GDTCORFlatFileStorage sharedInstance]];
  });
  return sharedInstance;
}

- (instancetype)initWithStorage:(id<GDTCORStoragePromiseProtocol>)storage {
  self = [super init];
  if (self) {
    _storage = storage;
  }
  return self;
}

- (nonnull FBLPromise<NSNull *> *)logEventsDroppedForReason:(GDTCOREventDropReason)reason
                                                     events:(nonnull NSSet<GDTCOREvent *> *)events {
  __auto_type readWriteblock = ^GDTCORMetricsMetadata *(
      GDTCORMetricsMetadata *_Nullable metricsMetadata, NSError *_Nullable fetchError) {
    GDTCOREventMetricsCounter *metricsCounter =
        [GDTCOREventMetricsCounter counterWithEvents:[events allObjects] droppedForReason:reason];

    if (metricsMetadata) {
      GDTCOREventMetricsCounter *droppedEventCounter =
          [metricsMetadata.droppedEventCounter counterByMergingWithCounter:metricsCounter];

      return [GDTCORMetricsMetadata
          metadataWithCollectionStartDate:[metricsMetadata collectionStartDate]
                      eventMetricsCounter:droppedEventCounter];
    } else {
      // There was an error (e.g. empty storage); `metricsMetadata` is nil.
      GDTCORLogDebug(@"Error fetching metrics metadata: %@", fetchError);
      return [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate date]
                                                eventMetricsCounter:metricsCounter];
    }
  };

  return [_storage fetchAndUpdateClientMetricsWithReadWriteBlock:readWriteblock];
}

- (nonnull FBLPromise<GDTCORMetrics *> *)getAndResetMetrics {
  __block GDTCORMetricsMetadata *snapshottedMetricsMetadata = nil;

  __auto_type readWriteblock = ^GDTCORMetricsMetadata *(
      GDTCORMetricsMetadata *_Nullable metricsMetadata, NSError *_Nullable fetchError) {
    if (metricsMetadata) {
      snapshottedMetricsMetadata = metricsMetadata;
    } else {
      GDTCORLogDebug(@"Error fetching metrics metadata: %@", fetchError);
    }
    return [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate date]
                                              eventMetricsCounter:nil];
  };

  return FBLPromise
      .all(@[
        [_storage fetchAndUpdateClientMetricsWithReadWriteBlock:readWriteblock],
        [_storage fetchStorageMetadata]
      ])
      .then(^GDTCORMetrics *(NSArray *metricsMetadataAndStorageMetadata) {
        return
            [GDTCORMetrics metricsWithMetricsMetadata:metricsMetadataAndStorageMetadata.firstObject
                                      storageMetadata:metricsMetadataAndStorageMetadata.lastObject];
      });
}

- (nonnull FBLPromise<NSNull *> *)offerMetrics:(nonnull GDTCORMetrics *)metrics {
  __auto_type readWriteblock = ^GDTCORMetricsMetadata *(
      GDTCORMetricsMetadata *_Nullable metricsMetadata, NSError *_Nullable fetchError) {
    if (metricsMetadata) {
      if (metrics.collectionStartDate <= metricsMetadata.collectionStartDate) {
        // If the metrics to append are older than the metrics represented by
        // the currently stored metrics, then return a new metadata object that
        // incorporates the data from the given metrics.
        return [GDTCORMetricsMetadata
            metadataWithCollectionStartDate:[metricsMetadata collectionStartDate]
                        eventMetricsCounter:
                            [metricsMetadata.droppedEventCounter
                                counterByMergingWithCounter:metrics.droppedEventCounter]];
      } else {
        // This catches an edge case where the given metrics to append are
        // newer than metrics represented by the currently stored metrics
        // metadata. In this case, return the existing metadata object as the
        // given metrics are assumed to already be accounted for by the
        // currenly metadata.
        return metricsMetadata;
      }
    } else {
      // There was an error (e.g. empty storage); `metricsMetadata` is nil.
      GDTCORLogDebug(@"Error fetching metrics metadata: %@", fetchError);

      NSDate *now = [NSDate date];
      if (metrics.collectionStartDate <= now) {
        // The given metrics are were recorded up until now. They wouldn't
        // be offered if they were successfully uploaded so their
        // corresponding metadata can be safely placed back in storage.
        return [GDTCORMetricsMetadata metadataWithCollectionStartDate:metrics.collectionStartDate
                                                  eventMetricsCounter:metrics.droppedEventCounter];
      } else {
        // This catches an edge case where the given metrics are from the
        // future. If this occurs, ignore them and store an empty metadata
        // object intended to track metrics metadata from this time forward.
        return [GDTCORMetricsMetadata metadataWithCollectionStartDate:now eventMetricsCounter:nil];
      }
    }
  };

  return [_storage fetchAndUpdateClientMetricsWithReadWriteBlock:readWriteblock];
}

- (BOOL)isMetricsCollectionSupportedForTarget:(GDTCORTarget)target {
  switch (target) {
    // Only the Firelog backend supports metrics collection.
    case kGDTCORTargetFLL:
    case kGDTCORTargetCSH:
    case kGDTCORTargetTest:
      return YES;

    case kGDTCORTargetCCT:
    case kGDTCORTargetINT:
      return NO;
  }

  NSAssert(NO, @"This code path shouldn't be reached.");
}

#pragma mark - GDTCORStorageDelegate

- (void)storage:(id<GDTCORStoragePromiseProtocol>)storage
    didRemoveExpiredEvent:(GDTCOREvent *)event {
  [self logEventsDroppedForReason:GDTCOREventDropReasonMessageTooOld
                           events:[NSSet setWithObject:event]];
}

- (void)storage:(id<GDTCORStoragePromiseProtocol>)storage didDropEvent:(GDTCOREvent *)event {
  [self logEventsDroppedForReason:GDTCOREventDropReasonStorageFull
                           events:[NSSet setWithObject:event]];
}

@end
