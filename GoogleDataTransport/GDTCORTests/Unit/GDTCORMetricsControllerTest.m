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

#import "GoogleDataTransport/GDTCORTests/Unit/GDTCORTestCase.h"

#import "FBLPromise+Await.h"
#import "FBLPromise+Testing.h"

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetrics.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsController.h"

@interface GDTCORMetricsControllerTest : GDTCORTestCase
@end

@implementation GDTCORMetricsControllerTest

- (void)SKIP_testLoggedEventsAreFetchedAsMetrics {
  // Given
  GDTCORMetricsController *metricsController = [[GDTCORMetricsController alloc] init];

  // When
  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:[NSSet set]];

  // Then
  GDTCORMetrics *metrics = FBLPromiseAwait([metricsController getAndResetMetrics], nil);
  // TODO(ncooke3): Assert that the metrics contain the previously logged events.
}

- (void)SKIP_testLogEvents_WhenNoEvents_DoesNothing {
  // Given
  GDTCORMetricsController *metricsController = [[GDTCORMetricsController alloc] init];

  // When
  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:[NSSet set]];

  // Then
  // TODO(ncooke3): Assert that the metrics are empty with expected time window.
}

- (void)SKIP_testFetchMetrics_WhenNoMetricsAreStored_ReturnsEmptyMetrics {
  // Given
  GDTCORMetricsController *metricsController = [[GDTCORMetricsController alloc] init];

  // Then
  // TODO(ncooke3): Assert that fetched metrics are empty with expected time window.
}

- (void)
    SKIP_testFetchMetrics_WhenSomeMetricsNeedReupload_ReturnsLastConfirmedMetricsThatFailedToUpload {
  // Given
  GDTCORMetricsController *metricsController = [[GDTCORMetricsController alloc] init];
  // - Create pending metrics.
  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:[NSSet set]];

  // When
  GDTCORMetrics *metrics1 = [[GDTCORMetrics alloc] init];
  [metricsController confirmMetrics:metrics1 wereUploaded:NO];

  GDTCORMetrics *metrics2 = [[GDTCORMetrics alloc] init];
  [metricsController confirmMetrics:metrics2 wereUploaded:NO];

  // Then
  // - TODO(ncooke3): Add comment.
  GDTCORMetrics *fetchedMetrics1 = FBLPromiseAwait([metricsController getAndResetMetrics], nil);
  XCTAssertEqualObjects(fetchedMetrics1, metrics2);

  // - TODO(ncooke3): Add comment.
  GDTCORMetrics *fetchedMetrics2 = FBLPromiseAwait([metricsController getAndResetMetrics], nil);
  XCTAssertEqualObjects(fetchedMetrics2, metrics1);

  // - TODO(ncooke3): Add comment.
  GDTCORMetrics *fetchedMetrics3 = FBLPromiseAwait([metricsController getAndResetMetrics], nil);
  // TODO(ncooke3): Assert that `metricsPromise3`'s metrics contain logged events.

  // TODO(ncooke3): Assert that the metrics are empty with the expected test window.
}

- (void)SKIP_testFetchMetrics_WhenNoMetricsNeedReuploading_ReturnsNewMetricsFromPendingMetricsData {
  // Given
  GDTCORMetricsController *metricsController = [[GDTCORMetricsController alloc] init];
  // - Create and fetch pending metrics data.
  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:[NSSet set]];
  GDTCORMetrics *metrics = FBLPromiseAwait([metricsController getAndResetMetrics], nil);

  // - * Client begins uploading fetched metrics... *

  // When
  // - Create new pending metrics data.
  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:[NSSet set]];
  // - Confirm uploading metrics were successfully uploaded.
  [metricsController confirmMetrics:metrics wereUploaded:YES];

  // Then
  GDTCORMetrics *newPendingMetrics = FBLPromiseAwait([metricsController getAndResetMetrics], nil);
  // TODO(ncooke3): Assert that the metrics contain the new pending metrics data.

  // TODO(ncooke3): Assert that the metrics are empty with expected time window.
}

- (void)SKIP_testConfirmMetrics_WhenMetricsWereUploaded_DoesNothing {
  // Given
  GDTCORMetricsController *metricsController = [[GDTCORMetricsController alloc] init];
  // - TODO(ncooke3): Add context.
  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:[NSSet set]];
  GDTCORMetrics *metrics = FBLPromiseAwait([metricsController getAndResetMetrics], nil);

  // When
  [metricsController confirmMetrics:metrics wereUploaded:YES];

  // Then
  // TODO(ncooke3): Assert that pending metrics are empty with expected time window.
}

- (void)SKIP_testConfirmMetrics_WhenMetricsWereNotUploaded_SavesMetricsForRefetchingLater {
  // Given
  GDTCORMetricsController *metricsController = [[GDTCORMetricsController alloc] init];
  // - TODO(ncooke3): Add context.
  [metricsController logEventsDroppedForReason:GDTCOREventDropReasonUnknown events:[NSSet set]];
  GDTCORMetrics *metricsThatFailedToUpload =
      FBLPromiseAwait([metricsController getAndResetMetrics], nil);

  // When
  // - * Uploading metrics fails *
  // - Alert the metrics controller about the upload and save metrics for later.
  [metricsController confirmMetrics:metricsThatFailedToUpload wereUploaded:NO];

  // Then
  GDTCORMetrics *metricsToRetryUploading =
      FBLPromiseAwait([metricsController getAndResetMetrics], nil);
  XCTAssertEqualObjects(metricsToRetryUploading, metricsThatFailedToUpload);

  // TODO(ncooke3): Assert that pending metrics are empty with expected time window.
}

- (void)testIsMetricsCollectionSupportedForTarget {
  // Given
  GDTCORMetricsController *metricsController = [[GDTCORMetricsController alloc] init];
  NSDictionary *targetSupportMatrix = @{
    @(kGDTCORTargetTest) : @YES,
    @(kGDTCORTargetFLL) : @YES,
    @(kGDTCORTargetCSH) : @YES,
    @(kGDTCORTargetCCT) : @NO,
    @(kGDTCORTargetINT) : @NO
  };

  for (NSNumber *target in targetSupportMatrix) {
    // When
    BOOL isSupported = [metricsController isMetricsCollectionSupportedForTarget:target.intValue];
    // Then
    BOOL expectedIsSupported = [(NSNumber *)targetSupportMatrix[target] boolValue];
    XCTAssertEqual(isSupported, expectedIsSupported, @"Failed for GDTCORTarget: %@", target);
  }
}

- (void)testGDTCORMetricsControllerInstanceForTarget {
  // Metrics controller registration is done at `GDTCORMetricsController +load` time.
  // Assert that it is registered for the FLL and CSH targets, but not for CCT.
  XCTAssertNotNil(GDTCORMetricsControllerInstanceForTarget(kGDTCORTargetFLL));
  XCTAssertNotNil(GDTCORMetricsControllerInstanceForTarget(kGDTCORTargetCSH));
  XCTAssertNil(GDTCORMetricsControllerInstanceForTarget(kGDTCORTargetCCT));
}

@end
