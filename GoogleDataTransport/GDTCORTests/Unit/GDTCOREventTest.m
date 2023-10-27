/*
 * Copyright 2018 Google
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

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORProductData.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORTargets.h"

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORPlatform.h"
#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORRegistrar.h"
#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORStorageProtocol.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORClock.h"

#import "GoogleDataTransport/GDTCORTests/Unit/GDTCORTestCase.h"
#import "GoogleDataTransport/GDTCORTests/Unit/Helpers/GDTCORDataObjectTesterClasses.h"

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCOREvent_Private.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORFlatFileStorage.h"

@interface GDTCOREventTest : GDTCORTestCase

@end

@implementation GDTCOREventTest

/** Tests  initializers. */
- (void)testInit {
  // Test `- [GDTCOREvent initWithMappingID:target:]`
  XCTAssertNotNil([[GDTCOREvent alloc] initWithMappingID:@"1" target:kGDTCORTargetTest].eventID);
  XCTAssertNotNil([[GDTCOREvent alloc] initWithMappingID:@"1" target:kGDTCORTargetTest]);
  XCTAssertNil([[GDTCOREvent alloc] initWithMappingID:@"" target:kGDTCORTargetTest]);
  // Test `- [GDTCOREvent initWithMappingID:productData:target:]`
  GDTCORProductData *productData = [[GDTCORProductData alloc] initWithProductID:123456];
  GDTCOREvent *event1 = [[GDTCOREvent alloc] initWithMappingID:@"1"
                                                   productData:productData
                                                        target:kGDTCORTargetTest];
  XCTAssertNotNil(event1);
  XCTAssertNotNil(event1.productData);
  XCTAssertEqual(event1.productData.productID, 123456);
  GDTCOREvent *event2 = [[GDTCOREvent alloc] initWithMappingID:@"1"
                                                   productData:nil
                                                        target:kGDTCORTargetTest];
  XCTAssertNotNil(event2);
  XCTAssertNil(event2.productData);
}

/** Tests NSKeyedArchiver encoding and decoding. */
- (void)testArchiving {
  // Test round trip archive of event with `nil` product data.
  GDTCOREvent *event = [[GDTCOREvent alloc] initWithMappingID:@"testID" target:kGDTCORTargetTest];
  GDTCOREvent *roundTripEvent = [self assertArchiveUnarchiveRoundTripForEvent:event];
  XCTAssertEqualObjects(event, roundTripEvent);

  // Test round trip archive of event with non-`nil` product data.
  GDTCORProductData *productData = [[GDTCORProductData alloc] initWithProductID:123456];
  GDTCOREvent *eventWithProductData = [[GDTCOREvent alloc] initWithMappingID:@"testID"
                                                                 productData:productData
                                                                      target:kGDTCORTargetTest];
  GDTCOREvent *roundTripEventWithProductData =
      [self assertArchiveUnarchiveRoundTripForEvent:eventWithProductData];
  XCTAssertEqualObjects(eventWithProductData, roundTripEventWithProductData);
}

/** Tests setting variables on a GDTCOREvent instance.*/
- (void)testSettingVariables {
  XCTAssertTrue([GDTCOREvent supportsSecureCoding]);
  GDTCOREvent *event = [[GDTCOREvent alloc] initWithMappingID:@"testing" target:kGDTCORTargetTest];
  event.clockSnapshot = [GDTCORClock snapshot];
  event.qosTier = GDTCOREventQoSTelemetry;
  XCTAssertNotNil(event);
  XCTAssertNotNil(event.mappingID);
  XCTAssertNotNil(@(event.target));
  XCTAssertEqual(event.qosTier, GDTCOREventQoSTelemetry);
  XCTAssertNotNil(event.clockSnapshot);
  XCTAssertNil(event.customBytes);
}

/** Tests equality between GDTCOREvents. */
- (void)testIsEqualAndHash {
  NSError *error1;
  GDTCOREvent *event1 = [self eventWithMappingID:@"1018"
                                     productData:nil
                                          target:kGDTCORTargetTest
                                           error:&error1];
  XCTAssertNil(error1);

  NSError *error2;
  GDTCOREvent *event2 = [self eventWithMappingID:@"1018"
                                     productData:nil
                                          target:kGDTCORTargetTest
                                           error:&error2];
  XCTAssertNil(error2);
  XCTAssertEqual([event1 hash], [event2 hash]);
  XCTAssertEqualObjects(event1, event2);

  // This only really tests that changing the timezoneOffsetSeconds value causes a change in hash.
  [event2.clockSnapshot setValue:@(-25201) forKeyPath:@"timezoneOffsetSeconds"];

  XCTAssertNotEqual([event1 hash], [event2 hash]);
  XCTAssertNotEqualObjects(event1, event2);

  // This only really tests that changing the `productData` value causes a change in hash.
  NSError *error3;
  GDTCOREvent *event3 = [self eventWithMappingID:@"1018"
                                     productData:[[GDTCORProductData alloc] initWithProductID:98765]
                                          target:kGDTCORTargetTest
                                           error:&error3];
  XCTAssertNil(error3);
  XCTAssertNotEqual([event1 hash], [event3 hash]);
}

/** Tests generating event IDs. */
- (void)testGenerateEventIDs {
  BOOL originalContinueAfterFailureValue = self.continueAfterFailure;
  self.continueAfterFailure = NO;
  NSMutableSet *generatedValues = [[NSMutableSet alloc] init];
  for (int i = 0; i < 100000; i++) {
    NSString *eventID = [GDTCOREvent nextEventID];
    XCTAssertNotNil(eventID);
    XCTAssertFalse([generatedValues containsObject:eventID]);
    [generatedValues addObject:eventID];
  }
  self.continueAfterFailure = originalContinueAfterFailureValue;
}

/** Archives the given event and returns its unarchived form. */
- (GDTCOREvent *)assertArchiveUnarchiveRoundTripForEvent:(GDTCOREvent *)event {
  XCTAssertTrue([GDTCOREvent supportsSecureCoding]);
  GDTCORClock *clockSnapshot = [GDTCORClock snapshot];
  int64_t timeMillis = clockSnapshot.timeMillis;
  int64_t timezoneOffsetSeconds = clockSnapshot.timezoneOffsetSeconds;
  event.dataObject = [[GDTCORDataObjectTesterSimple alloc] initWithString:@"someData"];
  event.qosTier = GDTCOREventQoSTelemetry;
  event.clockSnapshot = clockSnapshot;

  NSError *error;
  NSData *archiveData = GDTCOREncodeArchive(event, nil, &error);
  XCTAssertNil(error);
  XCTAssertNotNil(archiveData);

  // To ensure that all the objects being retained by the original event are dealloc'd.
  event = nil;
  error = nil;
  GDTCOREvent *decodedEvent =
      (GDTCOREvent *)GDTCORDecodeArchive([GDTCOREvent class], archiveData, &error);
  XCTAssertNil(error);
  XCTAssertNotNil(decodedEvent);
  XCTAssertEqualObjects(decodedEvent.mappingID, @"testID");
  XCTAssertEqual(decodedEvent.target, kGDTCORTargetTest);
  event.dataObject = [[GDTCORDataObjectTesterSimple alloc] initWithString:@"someData"];
  XCTAssertEqual(decodedEvent.qosTier, GDTCOREventQoSTelemetry);
  XCTAssertEqual(decodedEvent.clockSnapshot.timeMillis, timeMillis);
  XCTAssertEqual(decodedEvent.clockSnapshot.timezoneOffsetSeconds, timezoneOffsetSeconds);
  return decodedEvent;
}

/** Creates an event with a set snapshot time. */
- (GDTCOREvent *)eventWithMappingID:(NSString *)mappingID
                        productData:(nullable GDTCORProductData *)productData
                             target:(GDTCORTarget)target
                              error:(NSError **)outError {
  GDTCOREvent *event = [[GDTCOREvent alloc] initWithMappingID:@"1018"
                                                  productData:productData
                                                       target:kGDTCORTargetTest];
  event.eventID = @"123";
  event.clockSnapshot = [GDTCORClock snapshot];
  [event.clockSnapshot setValue:@(1553534573010) forKeyPath:@"timeMillis"];
  [event.clockSnapshot setValue:@(-25200) forKeyPath:@"timezoneOffsetSeconds"];
  [event.clockSnapshot setValue:@(1552576634359451) forKeyPath:@"kernelBootTimeNanoseconds"];
  [event.clockSnapshot setValue:@(961141365197) forKeyPath:@"uptimeNanoseconds"];
  event.qosTier = GDTCOREventQosDefault;
  event.dataObject = [[GDTCORDataObjectTesterSimple alloc] initWithString:@"someData"];
  event.customBytes = [NSJSONSerialization dataWithJSONObject:@{@"customParam1" : @"aValue1"}
                                                      options:0
                                                        error:outError];
  return event;
}

@end
