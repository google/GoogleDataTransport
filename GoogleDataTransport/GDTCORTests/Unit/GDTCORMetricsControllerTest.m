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

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORLogSourceMetrics.h"
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

  GDTCORLogSourceMetrics *expectedLogSourceMetrics =
      [GDTCORLogSourceMetrics metricsWithEvents:[droppedEvents allObjects]
                               droppedForReason:GDTCOREventDropReasonUnknown];

  // When
  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:droppedEvents];

  // Then
  __auto_type metricsPromise = [metricsController getAndResetMetrics];
  FBLWaitForPromisesWithTimeout(0.5);

  XCTAssertEqualObjects([metricsPromise.value logSourceMetrics], expectedLogSourceMetrics);
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

  GDTCORLogSourceMetrics *expectedLogSourceMetrics1 =
      [GDTCORLogSourceMetrics metricsWithEvents:[droppedEvents1 allObjects]
                               droppedForReason:GDTCOREventDropReasonUnknown];

  GDTCORLogSourceMetrics *expectedLogSourceMetrics2 =
      [GDTCORLogSourceMetrics metricsWithEvents:[droppedEvents2 allObjects]
                               droppedForReason:GDTCOREventDropReasonUnknown];

  GDTCORLogSourceMetrics *expectedLogSourceMetricsCombined = [expectedLogSourceMetrics1
      logSourceMetricsByMergingWithLogSourceMetrics:expectedLogSourceMetrics2];

  XCTAssertEqualObjects([metricsPromise.value logSourceMetrics], expectedLogSourceMetricsCombined);
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
  // The log source metrics should be empty.
  XCTAssertEqualObjects([metricsPromise2.value logSourceMetrics], [GDTCORLogSourceMetrics metrics]);
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

  GDTCORLogSourceMetrics *expectedLogSourceMetrics =
      [GDTCORLogSourceMetrics metricsWithEvents:[droppedEvents allObjects]
                               droppedForReason:GDTCOREventDropReasonUnknown];

  // When
  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:droppedEvents];

  // Then
  // - Assert that the retrieved metrics have the expected log source metrics.
  __auto_type metricsPromise1 = [metricsController getAndResetMetrics];
  FBLWaitForPromisesWithTimeout(0.5);

  XCTAssertEqualObjects([metricsPromise1.value logSourceMetrics], expectedLogSourceMetrics);

  // - Assert that metrics metadata was reset to start tracking metrics data
  //   from this point forward.
  __auto_type metricsPromise2 = [metricsController getAndResetMetrics];
  FBLWaitForPromisesWithTimeout(0.5);

  // Dates should be roughly equal (within one second of each other).
  XCTAssertEqualWithAccuracy(metricsPromise2.value.collectionStartDate.timeIntervalSince1970,
                             NSDate.date.timeIntervalSince1970, 1);
  // The log source metrics should be empty.
  XCTAssertEqualObjects([metricsPromise2.value logSourceMetrics], [GDTCORLogSourceMetrics metrics]);
}

- (void)testOfferMetrics_WhenStorageErrorAndOfferedMetricsAreValid_ThenAcceptMetrics {
  // Given
  GDTCORMetricsController *metricsController =
      [[GDTCORMetricsController alloc] initWithStorage:[GDTCORStorageFake storageFake]];

  // - Create valid metrics to offer.
  GDTCORMetricsMetadata *metricsMetadata =
      [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate distantPast]
                                            logSourceMetrics:[GDTCORLogSourceMetrics metrics]];

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
  XCTAssertEqualObjects([metricsPromise1.value logSourceMetrics], metricsMetadata.logSourceMetrics);
}

- (void)testOfferMetrics_WhenStorageErrorAndOfferedMetricsAreInvalid_ThenRejectMetrics {
  // Given
  GDTCORMetricsController *metricsController =
      [[GDTCORMetricsController alloc] initWithStorage:[GDTCORStorageFake storageFake]];

  // - Create invalid metrics to offer.
  GDTCORMetricsMetadata *metricsMetadata =
      [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate distantFuture]
                                            logSourceMetrics:[GDTCORLogSourceMetrics metrics]];

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
  // The log source metrics should be empty.
  XCTAssertEqualObjects([metricsPromise.value logSourceMetrics], [GDTCORLogSourceMetrics metrics]);
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

  GDTCORLogSourceMetrics *expectedLogSourceMetrics =
      [GDTCORLogSourceMetrics metricsWithEvents:[droppedEvents allObjects]
                               droppedForReason:GDTCOREventDropReasonUnknown];

  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:droppedEvents];

  // - Create invalid metrics to offer.
  GDTCORMetricsMetadata *metricsMetadata =
      [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate distantFuture]
                                            logSourceMetrics:[GDTCORLogSourceMetrics metrics]];

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
  XCTAssertEqualObjects([metricsPromise.value logSourceMetrics], expectedLogSourceMetrics);
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

  GDTCORLogSourceMetrics *originalLogSourceMetrics =
      [GDTCORLogSourceMetrics metricsWithEvents:[droppedEvents allObjects]
                               droppedForReason:GDTCOREventDropReasonUnknown];

  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:droppedEvents];

  // - Create valid metrics to offer.
  NSSet<GDTCOREvent *> *droppedEventsToOffer = [NSSet setWithArray:@[
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_2" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_2" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_source_3" target:kGDTCORTargetTest],
  ]];

  GDTCORLogSourceMetrics *counterToOffer =
      [GDTCORLogSourceMetrics metricsWithEvents:[droppedEventsToOffer allObjects]
                               droppedForReason:GDTCOREventDropReasonUnknown];

  GDTCORMetricsMetadata *metricsMetadata =
      [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate distantPast]
                                            logSourceMetrics:counterToOffer];

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
  GDTCORLogSourceMetrics *expectedCombinedLogSourceMetrics =
      [originalLogSourceMetrics logSourceMetricsByMergingWithLogSourceMetrics:counterToOffer];
  XCTAssertEqualObjects([metricsPromise.value logSourceMetrics], expectedCombinedLogSourceMetrics);
}

@end
