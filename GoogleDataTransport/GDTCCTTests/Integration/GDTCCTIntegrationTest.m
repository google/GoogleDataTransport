/*
 * Copyright 2019 Google
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

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORConsoleLogger.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREventDataObject.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORTransport.h"

#import <SystemConfiguration/SCNetworkReachability.h>

#import "GoogleDataTransport/GDTCCTLibrary/Private/GDTCCTUploader.h"
#import "GoogleDataTransport/GDTCCTTests/Unit/TestServer/GDTCCTTestServer.h"
#import "GoogleDataTransport/GDTCORTests/Common/Categories/GDTCORFlatFileStorage+Testing.h"

#import <nanopb/pb.h>
#import <nanopb/pb_decode.h>
#import <nanopb/pb_encode.h>
#import "GoogleDataTransport/GDTCCTLibrary/Protogen/nanopb/cct.nanopb.h"

@interface NSData (GDTCOREventDataObject) <GDTCOREventDataObject>
@end

@implementation NSData (GDTCOREventDataObject)

- (NSData *)transportBytes {
  return [self copy];
}

@end

@interface GDTCCTIntegrationTest : XCTestCase
/** If YES, allow the recursive generating of events. */
@property(nonatomic) BOOL generateEvents;

/** The total number of events generated for this test. */
@property(nonatomic) NSInteger totalEventsGenerated;

/** Events passed to GDT to be sent. */
@property(nonatomic) NSMutableArray<GDTCOREvent *> *scheduledEvents;

/** Events decoded from the request received by the server. */
@property(nonatomic) NSMutableArray<GDTCOREvent *> *serverReceivedEvents;

/** The transporter used by the test. */
@property(nonatomic) GDTCORTransport *transport;

/** The local HTTP server to use for testing. */
@property(nonatomic) GDTCCTTestServer *testServer;

@end

@implementation GDTCCTIntegrationTest

- (void)setUp {
  // Make sure clean storage state before start.
  [[GDTCORFlatFileStorage sharedInstance] reset];

  // Reset events.
  self.scheduledEvents = [NSMutableArray array];
  self.serverReceivedEvents = [NSMutableArray array];

  // Don't recursively generate events by default.
  self.generateEvents = NO;
  self.totalEventsGenerated = 0;

  self.testServer = [[GDTCCTTestServer alloc] init];
  self.testServer.responseNextRequestWaitTime = 0;
  [self.testServer registerLogBatchPath];
  [self.testServer start];
  XCTAssertTrue(self.testServer.isRunning);

  GDTCCTUploader.testServerURL =
      [self.testServer.serverURL URLByAppendingPathComponent:@"logBatch"];

  self.transport = [[GDTCORTransport alloc] initWithMappingID:@"1018"
                                                 transformers:nil
                                                       target:kGDTCORTargetCSH];
}

- (void)tearDown {
  XCTAssert([[GDTCCTUploader sharedInstance] waitForUploadFinishedWithTimeout:2]);
  [super tearDown];
}

/** Tests sending data to CCT with a high priority event if network conditions are good. */
- (void)testSendingDataToCCT {
  // Send a number of events across multiple queues in order to ensure the threading is working as
  // expected.
  dispatch_queue_t queue1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_queue_t queue2 = dispatch_queue_create("com.gdtcct.test", DISPATCH_QUEUE_SERIAL);
  for (int i = 0; i < 12; i++) {
    int result = i % 3;
    if (result == 0) {
      [self generateEventWithQoSTier:GDTCOREventQosDefault];
    } else if (result == 1) {
      dispatch_async(queue1, ^{
        [self generateEventWithQoSTier:GDTCOREventQosDefault];
      });
    } else if (result == 2) {
      dispatch_async(queue2, ^{
        [self generateEventWithQoSTier:GDTCOREventQosDefault];
      });
    }
  }

  XCTestExpectation *eventsUploaded = [self expectationForEventsToUpload];

  // Send a high priority event to flush events.
  [self generateEventWithQoSTier:GDTCOREventQoSFast];

  // Wait for events to be uploaded.
  [self waitForExpectations:@[ eventsUploaded ] timeout:60.0];

  // Validate sent events content.
  [self assertAllScheduledEventsWereReceived];
}

- (void)testRunsWithoutCrashing {
  // Just run for a minute whilst generating events.
  NSInteger secondsToRun = 65;
  self.generateEvents = YES;

  XCTestExpectation *eventsUploaded = [self expectationForEventsToUpload];
  eventsUploaded.expectedFulfillmentCount = 2;

  [self recursivelyGenerateEvent];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(secondsToRun * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   self.generateEvents = NO;

                   // Send a high priority event to flush other events.
                   [self generateEventWithQoSTier:GDTCOREventQoSFast];
                 });

  // Wait for events to be uploaded.
  [self waitForExpectations:@[ eventsUploaded ] timeout:secondsToRun + 5];

  // Validate sent events content.
  [self assertAllScheduledEventsWereReceived];
}

#pragma mark - Helpers

/** Generates an event and sends it through the transport infrastructure. */
- (void)generateEventWithQoSTier:(GDTCOREventQoS)qosTier {
  GDTCOREvent *event = [self.transport eventForTransport];
  event.dataObject = [[[NSUUID UUID] UUIDString] dataUsingEncoding:NSUTF8StringEncoding];
  event.qosTier = qosTier;
  [self.transport sendDataEvent:event
                     onComplete:^(BOOL wasWritten, NSError *_Nullable error) {
                       NSLog(@"Storing a data event completed.");
                     }];
  dispatch_async(dispatch_get_main_queue(), ^{
    self.totalEventsGenerated += 1;
    [self.scheduledEvents addObject:event];
  });
}

/** Generates events recursively at random intervals between 0 and 5 seconds. */
- (void)recursivelyGenerateEvent {
  if (self.generateEvents) {
    [self generateEventWithQoSTier:GDTCOREventQosDefault];
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(arc4random_uniform(6) * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          [self recursivelyGenerateEvent];
        });
  }
}

- (XCTestExpectation *)expectationForEventsToUpload {
  XCTestExpectation *responseSentExpectation = [self expectationWithDescription:@"response sent"];

  __auto_type __weak weakSelf = self;
  self.testServer.requestHandler =
      ^(GCDWebServerRequest *_Nonnull request, GCDWebServerResponse *_Nullable suggestedResponse,
        GCDWebServerCompletionBlock _Nonnull completionBlock) {
        __auto_type strongSelf = weakSelf;
        if (strongSelf == nil) {
          XCTFail();
          return;
        }

        // Decode events.
        GCDWebServerDataRequest *dataRequest = (GCDWebServerDataRequest *)request;
        NSError *decodeError;
        gdt_cct_BatchedLogRequest decodedRequest = [weakSelf requestWithData:dataRequest.data
                                                                       error:&decodeError];
        __auto_type events = [weakSelf eventsWithBatchRequest:decodedRequest error:&decodeError];
        XCTAssertNil(decodeError);
        [weakSelf.serverReceivedEvents addObjectsFromArray:events];

        // Send response.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
                         completionBlock(suggestedResponse);
                       });

        [responseSentExpectation fulfill];
      };

  return responseSentExpectation;
}

- (gdt_cct_BatchedLogRequest)requestWithData:(NSData *)data error:(NSError **)outError {
  gdt_cct_BatchedLogRequest request = gdt_cct_BatchedLogRequest_init_default;
  pb_istream_t istream = pb_istream_from_buffer([data bytes], [data length]);
  if (!pb_decode(&istream, gdt_cct_BatchedLogRequest_fields, &request)) {
    NSString *nanopb_error = [NSString stringWithFormat:@"%s", PB_GET_ERROR(&istream)];
    NSDictionary *userInfo = @{@"nanopb error:" : nanopb_error};
    if (outError != NULL) {
      *outError = [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:userInfo];
    }
    request = (gdt_cct_BatchedLogRequest)gdt_cct_BatchedLogRequest_init_default;
  }
  return request;
}

- (NSArray<GDTCOREvent *> *)eventsWithBatchRequest:(gdt_cct_BatchedLogRequest)batchRequest
                                             error:(NSError **)outError {
  NSMutableArray<GDTCOREvent *> *events = [NSMutableArray array];

  for (NSUInteger reqIdx = 0; reqIdx < batchRequest.log_request_count; reqIdx++) {
    gdt_cct_LogRequest request = batchRequest.log_request[reqIdx];

    NSString *mappingID = @(request.log_source).stringValue;

    for (NSUInteger eventIdx = 0; eventIdx < request.log_event_count; eventIdx++) {
      gdt_cct_LogEvent event = request.log_event[eventIdx];

      GDTCOREvent *decodedEvent = [[GDTCOREvent alloc] initWithMappingID:mappingID
                                                                  target:kGDTCORTargetTest];
      decodedEvent.dataObject = [NSData dataWithBytes:event.source_extension->bytes
                                               length:event.source_extension->size];

      [events addObject:decodedEvent];
    }
  }

  return [events copy];
}

- (void)assertAllScheduledEventsWereReceived {
  // Assume unique payload.
  __auto_type scheduledEventsByPayload =
      [self eventsByPayloadWithEvents:[self.scheduledEvents copy]];
  __auto_type receivedEventsByPayload =
      [self eventsByPayloadWithEvents:[self.serverReceivedEvents copy]];

  XCTAssertEqual(self.scheduledEvents.count, self.serverReceivedEvents.count);
  XCTAssertEqualObjects([NSSet setWithArray:scheduledEventsByPayload.allKeys],
                        [NSSet setWithArray:receivedEventsByPayload.allKeys]);

  [scheduledEventsByPayload
      enumerateKeysAndObjectsUsingBlock:^(
          NSData *_Nonnull key, GDTCOREvent *_Nonnull scheduledEvent, BOOL *_Nonnull stop) {
        GDTCOREvent *receivedEvent = receivedEventsByPayload[key];
        XCTAssertNotNil(receivedEvent);
        XCTAssertEqualObjects(scheduledEvent.mappingID, receivedEvent.mappingID);
        XCTAssertEqualObjects(scheduledEvent.clockSnapshot, receivedEvent.clockSnapshot);
      }];
}

- (NSDictionary<NSData *, GDTCOREvent *> *)eventsByPayloadWithEvents:
    (NSArray<GDTCOREvent *> *)events {
  NSMutableDictionary<NSData *, GDTCOREvent *> *eventsByPayload =
      [NSMutableDictionary dictionaryWithCapacity:self.scheduledEvents.count];
  for (GDTCOREvent *event in events) {
    eventsByPayload[event.serializedDataObjectBytes] = event;
  }

  XCTAssertEqual(events.count, eventsByPayload.count, @"The event payloads must be unique");

  return eventsByPayload;
}

@end
