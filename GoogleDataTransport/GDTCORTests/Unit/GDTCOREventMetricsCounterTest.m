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

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCOREventMetricsCounter.h"

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCOREventDropReason.h"
#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORPlatform.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"

typedef NSDictionary<NSNumber *, NSNumber *> GDTCORDroppedEventCounter;

@interface GDTCOREventMetricsCounter (Internal)

/// Designated initializer exposed for testing.
- (instancetype)initWithDroppedEventCounterByMappingID:
    (NSDictionary<NSString *, GDTCORDroppedEventCounter *> *)droppedEventCounterByMappingID;

@end

@interface GDTCOREventMetricsCounterTest : GDTCORTestCase
@end

@implementation GDTCOREventMetricsCounterTest

- (void)testCounterFactoryCreatesAndReturnsCounter {
  // Given
  GDTCOREventMetricsCounter *eventMetricsCounter1 = [GDTCOREventMetricsCounter counter];
  GDTCOREventMetricsCounter *eventMetricsCounter2 = [GDTCOREventMetricsCounter counter];
  // Then
  XCTAssertFalse(eventMetricsCounter1 == eventMetricsCounter2);
}

- (void)testCounterFactoryReturnsEmptyCounter {
  // Given
  GDTCOREventMetricsCounter *eventMetricsCounter = [GDTCOREventMetricsCounter counter];
  // Then
  GDTCOREventMetricsCounter *expectedEventMetricsCounter =
      [[GDTCOREventMetricsCounter alloc] initWithDroppedEventCounterByMappingID:@{}];
  XCTAssertEqualObjects(eventMetricsCounter, expectedEventMetricsCounter);
}

- (void)testCounterWithEvents_WhenEventsAreEmpty_CreatesEmptyCounter {
  // Given
  GDTCOREventMetricsCounter *eventMetricsCounter =
      [GDTCOREventMetricsCounter counterWithEvents:@[]
                                  droppedForReason:GDTCOREventDropReasonUnknown];
  // Then
  XCTAssertEqualObjects(eventMetricsCounter, [GDTCOREventMetricsCounter counter]);
}

- (void)testCounterWithEvents {
  // Given
  NSArray *events1 = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest]
  ];

  GDTCOREventMetricsCounter *eventMetricsCounter1 =
      [GDTCOREventMetricsCounter counterWithEvents:events1
                                  droppedForReason:GDTCOREventDropReasonStorageFull];

  NSArray *events2 = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
  ];

  GDTCOREventMetricsCounter *eventMetricsCounter2 =
      [GDTCOREventMetricsCounter counterWithEvents:events2
                                  droppedForReason:GDTCOREventDropReasonServerError];

  // When
  GDTCOREventMetricsCounter *mergedEventMetricsCounter =
      [eventMetricsCounter1 counterByMergingWithCounter:eventMetricsCounter2];
  // - Assert that merging the above counters in other ways result in same counter.
  [self assertMergedCounterFromCounter1:eventMetricsCounter1 counter2:eventMetricsCounter2];

  // Then
  GDTCOREventMetricsCounter *expectedEventMetricsCounter =
      [[GDTCOREventMetricsCounter alloc] initWithDroppedEventCounterByMappingID:@{
        @"log_src_1" : @{@(GDTCOREventDropReasonStorageFull) : @(2)},
        @"log_src_2" : @{
          @(GDTCOREventDropReasonStorageFull) : @(1),
          @(GDTCOREventDropReasonServerError) : @(1),
        },
      }];
  XCTAssertEqualObjects(mergedEventMetricsCounter, expectedEventMetricsCounter);
}

- (void)testMergingCounters_WhenBothCountersAreEmpty_ReturnsEmptyCounter {
  // Given
  GDTCOREventMetricsCounter *eventMetricsCounter1 = [GDTCOREventMetricsCounter counter];
  GDTCOREventMetricsCounter *eventMetricsCounter2 = [GDTCOREventMetricsCounter counter];
  // Then
  [self assertMergedCounterFromCounter1:eventMetricsCounter1 counter2:eventMetricsCounter2];
}

- (void)testMergingCounters_WhenGivenCounterIsEmpty_ReturnsReceivingCounter {
  // Given
  GDTCOREvent *event = [[GDTCOREvent alloc] initWithMappingID:@"log_src" target:kGDTCORTargetFLL];
  GDTCOREventMetricsCounter *eventMetricsCounter1 =
      [GDTCOREventMetricsCounter counterWithEvents:@[ event ]
                                  droppedForReason:GDTCOREventDropReasonUnknown];
  GDTCOREventMetricsCounter *eventMetricsCounter2 = [GDTCOREventMetricsCounter counter];
  // When
  GDTCOREventMetricsCounter *mergedCounter =
      [eventMetricsCounter1 counterByMergingWithCounter:eventMetricsCounter2];
  [self assertMergedCounterFromCounter1:eventMetricsCounter1 counter2:eventMetricsCounter2];
  // Then
  XCTAssertEqualObjects(mergedCounter, eventMetricsCounter1);
  XCTAssertFalse(mergedCounter == eventMetricsCounter1);
}

- (void)testMergingCounters_WhenCounterKeysDontCollide {
  // Given
  NSArray *events1 = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_3" target:kGDTCORTargetTest],
  ];

  GDTCOREventMetricsCounter *eventMetricsCounter1 =
      [GDTCOREventMetricsCounter counterWithEvents:events1
                                  droppedForReason:GDTCOREventDropReasonStorageFull];

  NSArray *events2 = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_4" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_5" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_6" target:kGDTCORTargetTest],
  ];

  GDTCOREventMetricsCounter *eventMetricsCounter2 =
      [GDTCOREventMetricsCounter counterWithEvents:events2
                                  droppedForReason:GDTCOREventDropReasonStorageFull];

  // When
  GDTCOREventMetricsCounter *mergedEventMetricsCounter =
      [eventMetricsCounter1 counterByMergingWithCounter:eventMetricsCounter2];
  // - Assert that merging the above counters in other ways result in same counter.
  // [self assertMergedCounterFromCounter1:eventMetricsCounter1 counter2:eventMetricsCounter2];

  // Then
  // - Expect no collisions for both the mapping IDs and drop reasons.
  GDTCOREventMetricsCounter *expectedEventMetricsCounter =
      [[GDTCOREventMetricsCounter alloc] initWithDroppedEventCounterByMappingID:@{
        @"log_src_1" : @{@(GDTCOREventDropReasonStorageFull) : @(1)},
        @"log_src_2" : @{@(GDTCOREventDropReasonStorageFull) : @(1)},
        @"log_src_3" : @{@(GDTCOREventDropReasonStorageFull) : @(1)},
        @"log_src_4" : @{@(GDTCOREventDropReasonStorageFull) : @(1)},
        @"log_src_5" : @{@(GDTCOREventDropReasonStorageFull) : @(1)},
        @"log_src_6" : @{@(GDTCOREventDropReasonStorageFull) : @(1)},
      }];
  XCTAssertEqualObjects(mergedEventMetricsCounter, expectedEventMetricsCounter);
}

- (void)testMergingCounters_WhenCounterKeysCollide {
  // Given
  NSArray *events1 = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_3" target:kGDTCORTargetTest],
  ];

  GDTCOREventMetricsCounter *eventMetricsCounter1 =
      [GDTCOREventMetricsCounter counterWithEvents:events1
                                  droppedForReason:GDTCOREventDropReasonStorageFull];

  NSArray *events2 = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_3" target:kGDTCORTargetTest],
  ];

  GDTCOREventMetricsCounter *eventMetricsCounter2 =
      [GDTCOREventMetricsCounter counterWithEvents:events2
                                  droppedForReason:GDTCOREventDropReasonStorageFull];

  // When
  GDTCOREventMetricsCounter *mergedEventMetricsCounter =
      [eventMetricsCounter1 counterByMergingWithCounter:eventMetricsCounter2];
  // - Assert that merging the above counters in other ways result in same counter.
  [self assertMergedCounterFromCounter1:eventMetricsCounter1 counter2:eventMetricsCounter2];

  // Then
  // - Expect resolved collisions for both the mapping IDs and drop reasons.
  GDTCOREventMetricsCounter *expectedEventMetricsCounter =
      [[GDTCOREventMetricsCounter alloc] initWithDroppedEventCounterByMappingID:@{
        @"log_src_1" : @{@(GDTCOREventDropReasonStorageFull) : @(2)},
        @"log_src_2" : @{@(GDTCOREventDropReasonStorageFull) : @(2)},
        @"log_src_3" : @{@(GDTCOREventDropReasonStorageFull) : @(2)},
      }];
  XCTAssertEqualObjects(mergedEventMetricsCounter, expectedEventMetricsCounter);
}

- (void)testEqualityEdgeCases {
  GDTCOREventMetricsCounter *eventMetricsCounter1 = [GDTCOREventMetricsCounter counter];
  GDTCOREventMetricsCounter *eventMetricsCounter2 = eventMetricsCounter1;
  XCTAssert([eventMetricsCounter1 isEqual:eventMetricsCounter2]);
  XCTAssertFalse([eventMetricsCounter1 isEqual:@"some string"]);
  XCTAssertFalse([eventMetricsCounter1 isEqual:nil]);
}

- (void)testEqualObjectsHaveSameHash {
  // Given
  GDTCOREventMetricsCounter *eventMetricsCounter1 =
      [GDTCOREventMetricsCounter counterWithEvents:@[
        [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
      ]
                                  droppedForReason:GDTCOREventDropReasonStorageFull];

  GDTCOREventMetricsCounter *eventMetricsCounter2 =
      [GDTCOREventMetricsCounter counterWithEvents:@[
        [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
      ]
                                  droppedForReason:GDTCOREventDropReasonStorageFull];

  GDTCOREventMetricsCounter *eventMetricsCounter3 =
      [GDTCOREventMetricsCounter counterWithEvents:@[
        [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
        [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
      ]
                                  droppedForReason:GDTCOREventDropReasonStorageFull];

  // Then
  XCTAssertEqualObjects(eventMetricsCounter1, eventMetricsCounter2);
  XCTAssertEqual(eventMetricsCounter1.hash, eventMetricsCounter2.hash);
  XCTAssertNotEqualObjects(eventMetricsCounter2, eventMetricsCounter3);
  XCTAssertNotEqual(eventMetricsCounter2.hash, eventMetricsCounter3.hash);
}

- (void)testSecureCoding {
  // Given
  NSArray *events = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
  ];

  GDTCOREventMetricsCounter *eventMetricsCounter =
      [GDTCOREventMetricsCounter counterWithEvents:events
                                  droppedForReason:GDTCOREventDropReasonStorageFull];

  // When
  // - Encode the counter.
  NSError *encodeError;
  NSData *encodedCounter = GDTCOREncodeArchive(eventMetricsCounter, nil, &encodeError);
  XCTAssertNil(encodeError);
  XCTAssertNotNil(encodedCounter);

  // - Write it to disk.
  NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"counter.dat"];
  NSError *writeError;
  BOOL writeResult = GDTCORWriteDataToFile(encodedCounter, filePath, &writeError);
  XCTAssertNil(writeError);
  XCTAssertTrue(writeResult);

  // Then
  // - Decode the counter from disk.
  NSError *decodeError;
  GDTCOREventMetricsCounter *decodedCounter = (GDTCOREventMetricsCounter *)GDTCORDecodeArchive(
      GDTCOREventMetricsCounter.class, filePath, nil, &decodeError);
  XCTAssertNil(decodeError);
  XCTAssertNotNil(decodedCounter);
  XCTAssertEqualObjects(decodedCounter, eventMetricsCounter);
}

- (void)assertMergedCounterFromCounter1:(GDTCOREventMetricsCounter *)counter1
                               counter2:(GDTCOREventMetricsCounter *)counter2 {
  // There are three ways to merge the given counters, and all three ways
  // should result in the same merged counter.
  GDTCOREventMetricsCounter *mergedCounter1 = [counter1 counterByMergingWithCounter:counter2];

  GDTCOREventMetricsCounter *mergedCounter2 = [counter2 counterByMergingWithCounter:counter1];

  GDTCOREventMetricsCounter *mergedCounter3 = [[GDTCOREventMetricsCounter.counter
      counterByMergingWithCounter:counter1] counterByMergingWithCounter:counter2];

  XCTAssertEqualObjects(mergedCounter1, mergedCounter2);
  XCTAssertEqualObjects(mergedCounter2, mergedCounter3);
}

@end
