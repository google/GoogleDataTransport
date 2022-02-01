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

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsController.h"

@interface GDTCORMetricsControllerTest : GDTCORTestCase

@end

@implementation GDTCORMetricsControllerTest

// TODO(ncooke3): Implement.
- (void)testLoggedEventsAreFetchedAsMetrics {
  // Given
  // When
  // Then
}

// TODO(ncooke3): Implement.
- (void)testLogEvents_WhenNoEvents_DoesNothing {
  // Given
  // When
  // Then
}

// TODO(ncooke3): Implement.
- (void)testFetchMetrics_WhenNoMetricsAreStored_ReturnsEmptyMetrics {
  // Given
  // When
  // Then
}

// TODO(ncooke3): Implement.
- (void)testFetchMetrics_WhenSomeMetricsNeedReupload_ReturnsLastConfirmedMetricsThatFailedToUpload {
  // Given
  // When
  // Then
}

// TODO(ncooke3): Implement.
- (void)testFetchMetrics_WhenNoMetricsNeedReuploading_ReturnsNewMetricsFromPendingMetricsData {
  // Given
  // When
  // Then
}

// TODO(ncooke3): Implement.
- (void)testConfirmMetrics_WhenMetricsWereUploaded_DoesNothing {
  // Given
  // When
  // Then
}

// TODO(ncooke3): Implement.
- (void)testConfirmMetrics_WhenMetricsWereNotUploaded_SavesMetricsForRefetchingLater {
  // Given
  // When
  // Then
}

// TODO(ncooke3): Implement.
- (void)testIsMetricsCollectionSupportedForTarget {
  // Given
  // When
  // Then
}

// TODO(ncooke3): Add a test for `GDTCORMetricsControllerInstanceForTarget`.

@end
