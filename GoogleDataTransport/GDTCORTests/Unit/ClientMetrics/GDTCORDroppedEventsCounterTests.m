/*
 * Copyright 2021 Google LLC
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

#import <XCTest/XCTest.h>

#import "GoogleDataTransport/GDTCORLibrary/ClientMetrics/GDTCORDroppedEventsCounter.h"

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORPlatform.h"

@interface GDTCORDroppedEventsCounterTests : XCTestCase

@end

@implementation GDTCORDroppedEventsCounterTests

- (void)testCounterCanBeEncodedAndDecoded {
  GDTCORDroppedEventsCounter *counter =
      [[GDTCORDroppedEventsCounter alloc] initWithEventCount:10
                                                  dropReason:GDTCOREventDropReasonStorageFull
                                                   mappingID:@"some_id"];

  NSData *encodedCounter = GDTCOREncodeArchive(counter, nil, nil);
  XCTAssertNotNil(encodedCounter);

  NSError *error;
  GDTCORDroppedEventsCounter *decodedCounter = (GDTCORDroppedEventsCounter *)GDTCORDecodeArchive(
      [GDTCORDroppedEventsCounter class], nil, encodedCounter, &error);

  XCTAssertNotNil(decodedCounter);
  XCTAssertTrue([decodedCounter isKindOfClass:[GDTCORDroppedEventsCounter class]]);
  XCTAssertEqual(decodedCounter.eventCount, counter.eventCount);
  XCTAssertEqual(decodedCounter.dropReason, counter.dropReason);
  XCTAssertEqualObjects(decodedCounter.mappingID, counter.mappingID);
}

- (void)testCounterWithCorruptedMappingIDCanBeDecoded {
  NSString *corruptedMappingID;
  GDTCORDroppedEventsCounter *counter =
      [[GDTCORDroppedEventsCounter alloc] initWithEventCount:10
                                                  dropReason:GDTCOREventDropReasonStorageFull
                                                   mappingID:corruptedMappingID];

  NSData *encodedCounter = GDTCOREncodeArchive(counter, nil, nil);
  XCTAssertNotNil(encodedCounter);

  NSError *error;
  GDTCORDroppedEventsCounter *decodedCounter = (GDTCORDroppedEventsCounter *)GDTCORDecodeArchive(
      [GDTCORDroppedEventsCounter class], nil, encodedCounter, &error);

  XCTAssertNotNil(decodedCounter);
  XCTAssertTrue([decodedCounter isKindOfClass:[GDTCORDroppedEventsCounter class]]);
  XCTAssertEqual(decodedCounter.eventCount, counter.eventCount);
  XCTAssertEqual(decodedCounter.dropReason, counter.dropReason);
  // Expect the `nil` mapping ID to be converted to an empty string.
  XCTAssertEqualObjects(decodedCounter.mappingID, @"");
}

@end
