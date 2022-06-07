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

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORLogSourceMetrics.h"

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCOREventDropReason.h"
#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORPlatform.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"

#pragma mark - GDTCORLogSourceMetrics + Internal

typedef NSDictionary<NSNumber *, NSNumber *> GDTCORDroppedEventLogSourceMetrics;

@interface GDTCORLogSourceMetrics (Internal)

/// Initializer exposed for testing.
- (instancetype)initWithDroppedEventCounterByLogSource:
    (NSDictionary<NSString *, GDTCORDroppedEventLogSourceMetrics *> *)
        droppedEventLogSourceMetricsByMappingID;

@end

#pragma mark - GDTCORLogSourceMetricsTest

@interface GDTCORLogSourceMetricsTest : GDTCORTestCase
@end

@implementation GDTCORLogSourceMetricsTest

- (void)testLogSourceMetricsFactoryCreatesAndReturnsLogSourceMetrics {
  // Given
  GDTCORLogSourceMetrics *logSourceMetrics1 = [GDTCORLogSourceMetrics metrics];
  GDTCORLogSourceMetrics *logSourceMetrics2 = [GDTCORLogSourceMetrics metrics];
  // Then
  XCTAssertFalse(logSourceMetrics1 == logSourceMetrics2);
}

- (void)testLogSourceMetricsFactoryReturnsEmptyLogSourceMetrics {
  // Given
  GDTCORLogSourceMetrics *logSourceMetrics = [GDTCORLogSourceMetrics metrics];
  // Then
  GDTCORLogSourceMetrics *expectedLogSourceMetrics =
      [[GDTCORLogSourceMetrics alloc] initWithDroppedEventCounterByLogSource:@{}];
  XCTAssertEqualObjects(logSourceMetrics, expectedLogSourceMetrics);
}

- (void)testLogSourceMetricsWithEvents_WhenEventsAreEmpty_CreatesEmptyLogSourceMetrics {
  // Given
  GDTCORLogSourceMetrics *logSourceMetrics =
      [GDTCORLogSourceMetrics metricsWithEvents:@[] droppedForReason:GDTCOREventDropReasonUnknown];
  // Then
  XCTAssertEqualObjects(logSourceMetrics, [GDTCORLogSourceMetrics metrics]);
}

- (void)testLogSourceMetricsWithEvents {
  // Given
  NSArray *events1 = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest]
  ];

  GDTCORLogSourceMetrics *logSourceMetrics1 =
      [GDTCORLogSourceMetrics metricsWithEvents:events1
                               droppedForReason:GDTCOREventDropReasonStorageFull];

  NSArray *events2 = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
  ];

  GDTCORLogSourceMetrics *logSourceMetrics2 =
      [GDTCORLogSourceMetrics metricsWithEvents:events2
                               droppedForReason:GDTCOREventDropReasonServerError];

  // When
  GDTCORLogSourceMetrics *mergedLogSourceMetrics =
      [logSourceMetrics1 logSourceMetricsByMergingWithLogSourceMetrics:logSourceMetrics2];
  // - Assert that merging the above log source metrics in other ways result in same log source
  // metrics.
  [self assertMergedLogSourceMetricsFromLogSourceMetrics1:logSourceMetrics1
                                        logSourceMetrics2:logSourceMetrics2];

  // Then
  GDTCORLogSourceMetrics *expectedLogSourceMetrics =
      [[GDTCORLogSourceMetrics alloc] initWithDroppedEventCounterByLogSource:@{
        @"log_src_1" : @{@(GDTCOREventDropReasonStorageFull) : @(2)},
        @"log_src_2" : @{
          @(GDTCOREventDropReasonStorageFull) : @(1),
          @(GDTCOREventDropReasonServerError) : @(1),
        },
      }];
  XCTAssertEqualObjects(mergedLogSourceMetrics, expectedLogSourceMetrics);
}

- (void)testMergingLogSourceMetrics_WhenBothLogSourceMetricsAreEmpty_ReturnsEmptyLogSourceMetrics {
  // Given
  GDTCORLogSourceMetrics *logSourceMetrics1 = [GDTCORLogSourceMetrics metrics];
  GDTCORLogSourceMetrics *logSourceMetrics2 = [GDTCORLogSourceMetrics metrics];
  // Then
  [self assertMergedLogSourceMetricsFromLogSourceMetrics1:logSourceMetrics1
                                        logSourceMetrics2:logSourceMetrics2];
}

- (void)
    testMergingLogSourceMetrics_WhenGivenLogSourceMetricsIsEmpty_ReturnsReceivingLogSourceMetrics {
  // Given
  GDTCOREvent *event = [[GDTCOREvent alloc] initWithMappingID:@"log_src" target:kGDTCORTargetFLL];
  GDTCORLogSourceMetrics *logSourceMetrics1 =
      [GDTCORLogSourceMetrics metricsWithEvents:@[ event ]
                               droppedForReason:GDTCOREventDropReasonUnknown];
  GDTCORLogSourceMetrics *logSourceMetrics2 = [GDTCORLogSourceMetrics metrics];
  // When
  GDTCORLogSourceMetrics *mergedLogSourceMetrics =
      [logSourceMetrics1 logSourceMetricsByMergingWithLogSourceMetrics:logSourceMetrics2];
  [self assertMergedLogSourceMetricsFromLogSourceMetrics1:logSourceMetrics1
                                        logSourceMetrics2:logSourceMetrics2];
  // Then
  XCTAssertEqualObjects(mergedLogSourceMetrics, logSourceMetrics1);
  XCTAssertFalse(mergedLogSourceMetrics == logSourceMetrics1);
}

- (void)testMergingLogSourceMetrics_WhenLogSourceMetricsKeysDontCollide {
  // Given
  NSArray *events1 = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_3" target:kGDTCORTargetTest],
  ];

  GDTCORLogSourceMetrics *logSourceMetrics1 =
      [GDTCORLogSourceMetrics metricsWithEvents:events1
                               droppedForReason:GDTCOREventDropReasonStorageFull];

  NSArray *events2 = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_4" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_5" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_6" target:kGDTCORTargetTest],
  ];

  GDTCORLogSourceMetrics *logSourceMetrics2 =
      [GDTCORLogSourceMetrics metricsWithEvents:events2
                               droppedForReason:GDTCOREventDropReasonStorageFull];

  // When
  GDTCORLogSourceMetrics *mergedLogSourceMetrics =
      [logSourceMetrics1 logSourceMetricsByMergingWithLogSourceMetrics:logSourceMetrics2];
  // - Assert that merging the above log source metrics in other ways result in same log source
  // metrics.
  [self assertMergedLogSourceMetricsFromLogSourceMetrics1:logSourceMetrics1
                                        logSourceMetrics2:logSourceMetrics2];

  // Then
  // - Expect no collisions for both the mapping IDs and drop reasons.
  GDTCORLogSourceMetrics *expectedLogSourceMetrics =
      [[GDTCORLogSourceMetrics alloc] initWithDroppedEventCounterByLogSource:@{
        @"log_src_1" : @{@(GDTCOREventDropReasonStorageFull) : @(1)},
        @"log_src_2" : @{@(GDTCOREventDropReasonStorageFull) : @(1)},
        @"log_src_3" : @{@(GDTCOREventDropReasonStorageFull) : @(1)},
        @"log_src_4" : @{@(GDTCOREventDropReasonStorageFull) : @(1)},
        @"log_src_5" : @{@(GDTCOREventDropReasonStorageFull) : @(1)},
        @"log_src_6" : @{@(GDTCOREventDropReasonStorageFull) : @(1)},
      }];
  XCTAssertEqualObjects(mergedLogSourceMetrics, expectedLogSourceMetrics);
}

- (void)testMergingLogSourceMetrics_WhenLogSourceMetricsKeysCollide {
  // Given
  NSArray *events1 = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_3" target:kGDTCORTargetTest],
  ];

  GDTCORLogSourceMetrics *logSourceMetrics1 =
      [GDTCORLogSourceMetrics metricsWithEvents:events1
                               droppedForReason:GDTCOREventDropReasonStorageFull];

  NSArray *events2 = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_3" target:kGDTCORTargetTest],
  ];

  GDTCORLogSourceMetrics *logSourceMetrics2 =
      [GDTCORLogSourceMetrics metricsWithEvents:events2
                               droppedForReason:GDTCOREventDropReasonStorageFull];

  // When
  GDTCORLogSourceMetrics *mergedLogSourceMetrics =
      [logSourceMetrics1 logSourceMetricsByMergingWithLogSourceMetrics:logSourceMetrics2];
  // - Assert that merging the above log source metrics in other ways result in same log source
  // metrics.
  [self assertMergedLogSourceMetricsFromLogSourceMetrics1:logSourceMetrics1
                                        logSourceMetrics2:logSourceMetrics2];

  // Then
  // - Expect resolved collisions for both the mapping IDs and drop reasons.
  GDTCORLogSourceMetrics *expectedLogSourceMetrics =
      [[GDTCORLogSourceMetrics alloc] initWithDroppedEventCounterByLogSource:@{
        @"log_src_1" : @{@(GDTCOREventDropReasonStorageFull) : @(2)},
        @"log_src_2" : @{@(GDTCOREventDropReasonStorageFull) : @(2)},
        @"log_src_3" : @{@(GDTCOREventDropReasonStorageFull) : @(2)},
      }];
  XCTAssertEqualObjects(mergedLogSourceMetrics, expectedLogSourceMetrics);
}

- (void)testEqualityEdgeCases {
  GDTCORLogSourceMetrics *logSourceMetrics1 = [GDTCORLogSourceMetrics metrics];
  GDTCORLogSourceMetrics *logSourceMetrics2 = logSourceMetrics1;
  XCTAssert([logSourceMetrics1 isEqual:logSourceMetrics2]);
  XCTAssertFalse([logSourceMetrics1 isEqual:@"some string"]);
  XCTAssertFalse([logSourceMetrics1 isEqual:nil]);
}

- (void)testEqualObjectsHaveSameHash {
  // Given
  GDTCORLogSourceMetrics *logSourceMetrics1 =
      [GDTCORLogSourceMetrics metricsWithEvents:@[
        [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
      ]
                               droppedForReason:GDTCOREventDropReasonStorageFull];

  GDTCORLogSourceMetrics *logSourceMetrics2 =
      [GDTCORLogSourceMetrics metricsWithEvents:@[
        [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
      ]
                               droppedForReason:GDTCOREventDropReasonStorageFull];

  GDTCORLogSourceMetrics *logSourceMetrics3 =
      [GDTCORLogSourceMetrics metricsWithEvents:@[
        [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
        [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
      ]
                               droppedForReason:GDTCOREventDropReasonStorageFull];

  // Then
  XCTAssertEqualObjects(logSourceMetrics1, logSourceMetrics2);
  XCTAssertEqual(logSourceMetrics1.hash, logSourceMetrics2.hash);
  XCTAssertNotEqualObjects(logSourceMetrics2, logSourceMetrics3);
  XCTAssertNotEqual(logSourceMetrics2.hash, logSourceMetrics3.hash);
}

- (void)testSecureCoding {
  // Given
  NSArray *events = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
  ];

  GDTCORLogSourceMetrics *logSourceMetrics =
      [GDTCORLogSourceMetrics metricsWithEvents:events
                               droppedForReason:GDTCOREventDropReasonStorageFull];

  // When
  // - Encode the log source metrics.
  NSError *encodeError;
  NSData *encodedLogSourceMetrics = GDTCOREncodeArchive(logSourceMetrics, nil, &encodeError);
  XCTAssertNil(encodeError);
  XCTAssertNotNil(encodedLogSourceMetrics);

  // Then
  // - Decode the log source metrics from disk.
  NSError *decodeError;
  GDTCORLogSourceMetrics *decodedLogSourceMetrics = (GDTCORLogSourceMetrics *)GDTCORDecodeArchive(
      GDTCORLogSourceMetrics.class, encodedLogSourceMetrics, &decodeError);
  XCTAssertNil(decodeError);
  XCTAssertNotNil(decodedLogSourceMetrics);
  XCTAssertEqualObjects(decodedLogSourceMetrics, logSourceMetrics);
}

- (void)testSecureCoding_WhenEncodingIsCorrupted {
  // Given
  // - Create an invalid instance and write its encoding to a file. When
  //   decoding, the invalid encoding should be treated as a corrupt encoding.
  GDTCORLogSourceMetrics *corruptedMetricsLogSourceMetrics =
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
      [[GDTCORLogSourceMetrics alloc] initWithDroppedEventCounterByLogSource:@"corrupted"];
#pragma clang diagnostic pop

  NSError *encodeError;
  NSData *encodedMetricsLogSourceMetrics =
      GDTCOREncodeArchive(corruptedMetricsLogSourceMetrics, nil, &encodeError);
  XCTAssertNil(encodeError);
  XCTAssertNotNil(encodedMetricsLogSourceMetrics);

  // When
  NSError *decodeError;
  GDTCORLogSourceMetrics *decodedMetricsLogSourceMetrics =
      (GDTCORLogSourceMetrics *)GDTCORDecodeArchive(GDTCORLogSourceMetrics.class,
                                                    encodedMetricsLogSourceMetrics, &decodeError);
  // Then
  XCTAssertNotNil(decodeError);
  XCTAssertNil(decodedMetricsLogSourceMetrics);
}

- (void)
    assertMergedLogSourceMetricsFromLogSourceMetrics1:(GDTCORLogSourceMetrics *)logSourceMetrics1
                                    logSourceMetrics2:(GDTCORLogSourceMetrics *)logSourceMetrics2 {
  // There are three ways to merge the given log source metrics, and all three ways
  // should result in the same merged log source metrics.
  GDTCORLogSourceMetrics *mergedLogSourceMetrics1 =
      [logSourceMetrics1 logSourceMetricsByMergingWithLogSourceMetrics:logSourceMetrics2];

  GDTCORLogSourceMetrics *mergedLogSourceMetrics2 =
      [logSourceMetrics2 logSourceMetricsByMergingWithLogSourceMetrics:logSourceMetrics1];

  GDTCORLogSourceMetrics *mergedLogSourceMetrics3 = [[GDTCORLogSourceMetrics.metrics
      logSourceMetricsByMergingWithLogSourceMetrics:logSourceMetrics1]
      logSourceMetricsByMergingWithLogSourceMetrics:logSourceMetrics2];

  XCTAssertEqualObjects(mergedLogSourceMetrics1, mergedLogSourceMetrics2);
  XCTAssertEqualObjects(mergedLogSourceMetrics2, mergedLogSourceMetrics3);
}

@end
