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

#import "GoogleDataTransport/GDTCORTests/Unit/GDTCORTestCase.h"

#import "FBLPromise+Await.h"
#import "FBLPromise+Testing.h"

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORTargets.h"

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCOREventMetricsCounter.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetrics.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsController.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsMetadata.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORStorageMetadata.h"

#import "GoogleDataTransport/GDTCORTests/Common/Fakes/GDTCORStorageFake.h"

@interface GDTCORMetricsControllerTest : GDTCORTestCase
@end

@implementation GDTCORMetricsControllerTest

- (void)testLoggingEvents_WhenEventSetIsEmpty_ThenNoOp {
  // Given
  GDTCORMetricsController *metricsController =
      [[GDTCORMetricsController alloc] initWithStorage:[GDTCORStorageFake storageFake]];

  // When
  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:[NSSet set]];

  // Then
  __auto_type metricsPromise = [metricsController getAndResetMetrics];
  FBLWaitForPromisesWithTimeout(0.5);
  XCTAssert([metricsPromise isRejected]);
}

- (void)testLoggingEvents_WhenNoMetricsAreStored_StoresEventsAsMetrics {
  // Given
  GDTCORMetricsController *metricsController =
      [[GDTCORMetricsController alloc] initWithStorage:[GDTCORStorageFake storageFake]];

  NSSet<GDTCOREvent *> *droppedEvents = [NSSet setWithArray:@[
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_2" target:kGDTCORTargetTest],
  ]];

  GDTCOREventMetricsCounter *expectedCounter =
      [GDTCOREventMetricsCounter counterWithEvents:[droppedEvents allObjects]
                                  droppedForReason:GDTCOREventDropReasonUnknown];

  // When
  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:droppedEvents];

  // Then
  __auto_type metricsPromise = [metricsController getAndResetMetrics];
  FBLWaitForPromisesWithTimeout(0.5);

  XCTAssertEqualObjects([metricsPromise.value droppedEventCounter], expectedCounter);
}

- (void)testLoggingEvents_WhenMetricsAreStored_StoresEventsAsMetrics {
  // Given
  GDTCORMetricsController *metricsController =
      [[GDTCORMetricsController alloc] initWithStorage:[GDTCORStorageFake storageFake]];

  NSSet<GDTCOREvent *> *droppedEvents1 = [NSSet setWithArray:@[
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_2" target:kGDTCORTargetTest],
  ]];

  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:droppedEvents1];

  // When
  NSSet<GDTCOREvent *> *droppedEvents2 = [NSSet setWithArray:@[
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_2" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_3" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_3" target:kGDTCORTargetTest],
  ]];

  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:droppedEvents2];

  // Then
  __auto_type metricsPromise = [metricsController getAndResetMetrics];
  FBLWaitForPromisesWithTimeout(0.5);

  GDTCOREventMetricsCounter *expectedCounter1 =
      [GDTCOREventMetricsCounter counterWithEvents:[droppedEvents1 allObjects]
                                  droppedForReason:GDTCOREventDropReasonUnknown];

  GDTCOREventMetricsCounter *expectedCounter2 =
      [GDTCOREventMetricsCounter counterWithEvents:[droppedEvents2 allObjects]
                                  droppedForReason:GDTCOREventDropReasonUnknown];

  GDTCOREventMetricsCounter *expectedCounterCombined =
      [expectedCounter1 counterByMergingWithCounter:expectedCounter2];

  XCTAssertEqualObjects([metricsPromise.value droppedEventCounter], expectedCounterCombined);
}

- (void)testGetAndResetMetrics_WhenNoMetricsDataIsStored_ReturnsRejectedPromise {
  // Given
  GDTCORMetricsController *metricsController =
      [[GDTCORMetricsController alloc] initWithStorage:[GDTCORStorageFake storageFake]];

  // When
  __auto_type metricsPromise = [metricsController getAndResetMetrics];

  // Then
  // - Assert that the retrieved metrics promise was rejected.
  FBLWaitForPromisesWithTimeout(0.5);
  XCTAssert(metricsPromise.isRejected);

  // - Assert that metrics metadata was reset to start tracking metrics data
  //   from this point forward.
  __auto_type metricsPromise2 = [metricsController getAndResetMetrics];
  FBLWaitForPromisesWithTimeout(0.5);

  // Dates should be roughly equal (within one second of each other).
  XCTAssertEqualWithAccuracy(metricsPromise2.value.collectionStartDate.timeIntervalSince1970,
                             NSDate.date.timeIntervalSince1970, 1);
  // The dropped event counter should be empty.
  XCTAssertEqualObjects([metricsPromise2.value droppedEventCounter],
                        [GDTCOREventMetricsCounter counter]);
}

- (void)testGetAndResetMetrics_WhenMetricsDataIsStored_ReturnsMetrics {
  // Given
  GDTCORMetricsController *metricsController =
      [[GDTCORMetricsController alloc] initWithStorage:[GDTCORStorageFake storageFake]];

  NSSet<GDTCOREvent *> *droppedEvents = [NSSet setWithArray:@[
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_2" target:kGDTCORTargetTest],
  ]];

  GDTCOREventMetricsCounter *expectedCounter =
      [GDTCOREventMetricsCounter counterWithEvents:[droppedEvents allObjects]
                                  droppedForReason:GDTCOREventDropReasonUnknown];

  // When
  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:droppedEvents];

  // Then
  // - Assert that the retrieved metrics have the expected dropped event counter.
  __auto_type metricsPromise1 = [metricsController getAndResetMetrics];
  FBLWaitForPromisesWithTimeout(0.5);

  XCTAssertEqualObjects([metricsPromise1.value droppedEventCounter], expectedCounter);

  // - Assert that metrics metadata was reset to start tracking metrics data
  //   from this point forward.
  __auto_type metricsPromise2 = [metricsController getAndResetMetrics];
  FBLWaitForPromisesWithTimeout(0.5);

  // Dates should be roughly equal (within one second of each other).
  XCTAssertEqualWithAccuracy(metricsPromise2.value.collectionStartDate.timeIntervalSince1970,
                             NSDate.date.timeIntervalSince1970, 1);
  // The dropped event counter should be empty.
  XCTAssertEqualObjects([metricsPromise2.value droppedEventCounter],
                        [GDTCOREventMetricsCounter counter]);
}

- (void)testOfferMetrics_WhenStorageErrorAndOfferedMetricsAreValid_ThenAcceptMetrics {
  // Given
  GDTCORMetricsController *metricsController =
      [[GDTCORMetricsController alloc] initWithStorage:[GDTCORStorageFake storageFake]];

  // - Create valid metrics to offer.
  GDTCORMetricsMetadata *metricsMetadata =
      [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate distantPast]
                                         eventMetricsCounter:[GDTCOREventMetricsCounter counter]];

  GDTCORStorageMetadata *storageMetadata =
      [GDTCORStorageMetadata metadataWithCurrentCacheSize:15 * 1000 * 1000    // 15 MB
                                             maxCacheSize:20 * 1000 * 1000];  // 20 MB

  GDTCORMetrics *metrics = [GDTCORMetrics metricsWithMetricsMetadata:metricsMetadata
                                                     storageMetadata:storageMetadata];

  // When
  // - Storage is empty and will pass back an error. See ``GDTCORStorageFake``.
  __auto_type offerPromise = [metricsController offerMetrics:metrics];

  // Then
  // - Assert promise was resolved.
  FBLWaitForPromisesWithTimeout(0.5);
  XCTAssert(offerPromise.isFulfilled);

  // - Assert that retrieving the metrics contains the metadata from the offered metrics.
  __auto_type metricsPromise1 = [metricsController getAndResetMetrics];
  FBLWaitForPromisesWithTimeout(0.5);
  XCTAssertEqualObjects([metricsPromise1.value collectionStartDate],
                        metricsMetadata.collectionStartDate);
  XCTAssertEqualObjects([metricsPromise1.value droppedEventCounter],
                        metricsMetadata.droppedEventCounter);
}

- (void)testOfferMetrics_WhenStorageErrorAndOfferedMetricsAreInvalid_ThenRejectMetrics {
  // Given
  GDTCORMetricsController *metricsController =
      [[GDTCORMetricsController alloc] initWithStorage:[GDTCORStorageFake storageFake]];

  // - Create invalid metrics to offer.
  GDTCORMetricsMetadata *metricsMetadata =
      [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate distantFuture]
                                         eventMetricsCounter:[GDTCOREventMetricsCounter counter]];

  GDTCORStorageMetadata *storageMetadata =
      [GDTCORStorageMetadata metadataWithCurrentCacheSize:15 * 1000 * 1000    // 15 MB
                                             maxCacheSize:20 * 1000 * 1000];  // 20 MB

  GDTCORMetrics *metrics = [GDTCORMetrics metricsWithMetricsMetadata:metricsMetadata
                                                     storageMetadata:storageMetadata];

  // When
  // - Storage is empty and will pass back an error. See ``GDTCORStorageFake``.
  __auto_type offerPromise = [metricsController offerMetrics:metrics];

  // Then
  // - Assert promise was resolved.
  FBLWaitForPromisesWithTimeout(0.5);
  XCTAssert(offerPromise.isFulfilled);

  // - Assert that retrieving the metrics contains the metadata from the offered metrics.
  __auto_type metricsPromise = [metricsController getAndResetMetrics];
  FBLWaitForPromisesWithTimeout(0.5);
  // Dates should be roughly equal (within one second of each other).
  XCTAssertEqualWithAccuracy(metricsPromise.value.collectionStartDate.timeIntervalSince1970,
                             NSDate.date.timeIntervalSince1970, 1);
  // The dropped event counter should be empty.
  XCTAssertEqualObjects([metricsPromise.value droppedEventCounter],
                        [GDTCOREventMetricsCounter counter]);
}

- (void)testOfferMetrics_WhenOfferedMetricsAreInvalid_ThenRejectMetrics {
  // Given
  GDTCORMetricsController *metricsController =
      [[GDTCORMetricsController alloc] initWithStorage:[GDTCORStorageFake storageFake]];

  // - Populate storage with metrics metadata from dropped events.
  NSSet<GDTCOREvent *> *droppedEvents = [NSSet setWithArray:@[
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_2" target:kGDTCORTargetTest],
  ]];

  GDTCOREventMetricsCounter *expectedCounter =
      [GDTCOREventMetricsCounter counterWithEvents:[droppedEvents allObjects]
                                  droppedForReason:GDTCOREventDropReasonUnknown];

  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:droppedEvents];

  // - Create invalid metrics to offer.
  GDTCORMetricsMetadata *metricsMetadata =
      [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate distantFuture]
                                         eventMetricsCounter:[GDTCOREventMetricsCounter counter]];

  GDTCORStorageMetadata *storageMetadata =
      [GDTCORStorageMetadata metadataWithCurrentCacheSize:15 * 1000 * 1000    // 15 MB
                                             maxCacheSize:20 * 1000 * 1000];  // 20 MB

  GDTCORMetrics *metrics = [GDTCORMetrics metricsWithMetricsMetadata:metricsMetadata
                                                     storageMetadata:storageMetadata];

  // When
  __auto_type offerPromise = [metricsController offerMetrics:metrics];

  // Then
  // - Assert promise was resolved.
  FBLWaitForPromisesWithTimeout(0.5);
  XCTAssert(offerPromise.isFulfilled);

  // - Assert that retrieving the metrics contains the metadata from the original metrics.
  __auto_type metricsPromise = [metricsController getAndResetMetrics];
  FBLWaitForPromisesWithTimeout(0.5);
  XCTAssertEqualObjects([metricsPromise.value droppedEventCounter], expectedCounter);
}

- (void)testOfferMetrics_WhenOfferedMetricsAreValid_ThenAcceptMetrics {
  // Given
  GDTCORMetricsController *metricsController =
      [[GDTCORMetricsController alloc] initWithStorage:[GDTCORStorageFake storageFake]];

  // - Populate storage with metrics metadata from dropped events.
  NSSet<GDTCOREvent *> *droppedEvents = [NSSet setWithArray:@[
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_2" target:kGDTCORTargetTest],
  ]];

  GDTCOREventMetricsCounter *originalCounter =
      [GDTCOREventMetricsCounter counterWithEvents:[droppedEvents allObjects]
                                  droppedForReason:GDTCOREventDropReasonUnknown];

  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:droppedEvents];

  // - Create valid metrics to offer.
  NSSet<GDTCOREvent *> *droppedEventsToOffer = [NSSet setWithArray:@[
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_2" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_2" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_3" target:kGDTCORTargetTest],
  ]];

  GDTCOREventMetricsCounter *counterToOffer =
      [GDTCOREventMetricsCounter counterWithEvents:[droppedEventsToOffer allObjects]
                                  droppedForReason:GDTCOREventDropReasonUnknown];

  GDTCORMetricsMetadata *metricsMetadata =
      [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate distantPast]
                                         eventMetricsCounter:counterToOffer];

  GDTCORStorageMetadata *storageMetadata =
      [GDTCORStorageMetadata metadataWithCurrentCacheSize:15 * 1000 * 1000    // 15 MB
                                             maxCacheSize:20 * 1000 * 1000];  // 20 MB

  GDTCORMetrics *metrics = [GDTCORMetrics metricsWithMetricsMetadata:metricsMetadata
                                                     storageMetadata:storageMetadata];

  // When
  __auto_type offerPromise = [metricsController offerMetrics:metrics];

  // Then
  // - Assert promise was resolved.
  FBLWaitForPromisesWithTimeout(0.5);
  XCTAssert(offerPromise.isFulfilled);

  // - Assert that retrieving the metrics contains the combined metadata from
  //   the original metrics and the offered metrics.
  __auto_type metricsPromise = [metricsController getAndResetMetrics];
  FBLWaitForPromisesWithTimeout(0.5);
  XCTAssertEqualObjects([metricsPromise.value collectionStartDate], [NSDate distantPast]);
  GDTCOREventMetricsCounter *expectedCombinedCounter =
      [originalCounter counterByMergingWithCounter:counterToOffer];
  XCTAssertEqualObjects([metricsPromise.value droppedEventCounter], expectedCombinedCounter);
}

@end
