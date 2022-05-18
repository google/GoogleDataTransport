/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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

// TODO(ncooke3): Document.
static NSString *const kMetricsLibraryDataKey = @"metrics-library-data";

@interface GDTCORMetricsController ()
// TODO(ncooke3): Document.
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
  GDTCORStorageLibraryDataReadWriteBlock readWriteblock =
      ^GDTCORMetricsMetadata *(GDTCORMetricsMetadata *currentMetricsMetadata, NSError *fetchError) {
    if (fetchError) {
      GDTCORLogDebug(@"Error fetching metrics metadata: %@", fetchError);
    }

    // Create and store metrics metadata based on the current metrics metadata, if any exists.
    NSDate *collectedSinceDate = [NSDate date];
    GDTCOREventMetricsCounter *metricsCounter =
        [GDTCOREventMetricsCounter counterWithEvents:[events allObjects] droppedForReason:reason];

    if (currentMetricsMetadata) {
      collectedSinceDate = [currentMetricsMetadata collectionStartDate];
      metricsCounter =
          [[currentMetricsMetadata droppedEventCounter] counterByMergingWithCounter:metricsCounter];
    }

    return [GDTCORMetricsMetadata metadataWithCollectionStartDate:collectedSinceDate
                                              eventMetricsCounter:metricsCounter];
  };

  return [_storage fetchAndUpdateLibraryDataForKey:kMetricsLibraryDataKey
                                             klass:[GDTCORMetricsMetadata class]
                                    readWriteBlock:readWriteblock]
      .then(^id _Nullable(GDTCORLibraryData _Nullable value) {
        return nil;
      });
}

- (nonnull FBLPromise<GDTCORMetrics *> *)getAndResetMetrics {
  __block GDTCORMetricsMetadata *snapshottedMetricsMetadata = nil;

  GDTCORStorageLibraryDataReadWriteBlock readWriteblock =
      ^GDTCORMetricsMetadata *(GDTCORMetricsMetadata *currentMetricsMetadata, NSError *fetchError) {
    if (fetchError) {
      GDTCORLogDebug(@"Error fetching metrics metadata: %@", fetchError);
    }

    snapshottedMetricsMetadata = currentMetricsMetadata;

    // TODO(ncooke3): Revisit passing `nil` to `eventMetricsCounter` param.
    return [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate date]
                                              eventMetricsCounter:nil];
  };

  return [_storage fetchAndUpdateLibraryDataForKey:kMetricsLibraryDataKey
                                             klass:[GDTCORMetricsMetadata class]
                                    readWriteBlock:readWriteblock]
      .then(^id _Nullable(GDTCORLibraryData _Nullable value) {
        // TODO(ncooke3): Create metrics object using snapshottedMetadata.
        return nil;
      });
}

- (nonnull FBLPromise<NSNull *> *)offerMetrics:(nonnull GDTCORMetrics *)metrics {
  GDTCORStorageLibraryDataReadWriteBlock readWriteblock = ^GDTCORMetricsMetadata *(
      GDTCORMetricsMetadata *_Nullable metricsMetadata, NSError *_Nullable fetchError) {
    if (metricsMetadata && metrics.collectionStartDate < metricsMetadata.collectionStartDate) {
      // If the metrics to append are older than the metrics represented by the
      // currently stored metrics, then return a new metadata object that
      // incorporates the data from the given metrics.
      return [GDTCORMetricsMetadata
          metadataWithCollectionStartDate:[metricsMetadata collectionStartDate]
                      eventMetricsCounter:
                          [metricsMetadata.droppedEventCounter
                              counterByMergingWithCounter:metrics.droppedEventCounter]];
    } else if (metricsMetadata) {
      // This will catch an edge case where the given metrics to append are
      // newer than metrics represented by the currently stored metrics
      // metadata. In this case, return the existing metadata object as the
      // given metrics can be safely ignored.
      return metricsMetadata;
    } else {
      GDTCORLogDebug(@"Error fetching metrics metadata: %@", fetchError);
      // There was an error (e.g. empty storage); `metricsMetadata` is nil.
      // If this occurs, store an empty metadata object intended to track
      // metrics metadata from this time forward.
      return [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate date]
                                                eventMetricsCounter:nil];
    }
  };

  return [_storage fetchAndUpdateLibraryDataForKey:kMetricsLibraryDataKey
                                             klass:[GDTCORMetricsMetadata class]
                                    readWriteBlock:readWriteblock]
      .then(^id _Nullable(GDTCORLibraryData _Nullable value) {
        return nil;
      });
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
