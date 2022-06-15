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

#import <XCTest/XCTest.h>

#import "GoogleDataTransport/GDTCCTLibrary/Private/GDTCORMetrics+GDTCCTSupport.h"

#import "GoogleDataTransport/GDTCCTTests/Unit/Helpers/GDTCCTTestRequestParser.h"
#import "GoogleDataTransport/GDTCCTTests/Unit/Helpers/GDTCORMetricsTestHelpers.h"

@interface GDTCORMetrics_GDTCCTSupportTests : XCTestCase
@end

@implementation GDTCORMetrics_GDTCCTSupportTests

- (void)testTransportBytes {
  // Given
  GDTCORMetrics *metrics = [GDTCORMetricsTestHelpers metricsWithGeneratedDroppedEventCounters];

  // When
  NSData *metricsProtoData = [metrics transportBytes];
  XCTAssertNotNil(metricsProtoData);
  XCTAssertGreaterThan(metricsProtoData.length, 0);

  // Then
  NSError *decodeError = nil;
  gdt_client_metrics_ClientMetrics metricsProto =
      [GDTCCTTestRequestParser metricsProtoWithData:metricsProtoData error:&decodeError];
  XCTAssertNil(decodeError);

  [GDTCORMetricsTestHelpers assertMetrics:metrics correspondToProto:metricsProto];
}

- (void)testTransportBytes_WhenMetricsContainNoDroppedEventData {
  // Given
  GDTCORMetrics *metrics = [GDTCORMetricsTestHelpers metricsWithEmptyDroppedEventCounters];

  // When
  NSData *metricsProtoData = [metrics transportBytes];
  XCTAssertNotNil(metricsProtoData);
  XCTAssertGreaterThan(metricsProtoData.length, 0);

  // Then
  NSError *decodeError = nil;
  gdt_client_metrics_ClientMetrics metricsProto =
      [GDTCCTTestRequestParser metricsProtoWithData:metricsProtoData error:&decodeError];
  XCTAssertNil(decodeError);

  [GDTCORMetricsTestHelpers assertMetrics:metrics correspondToProto:metricsProto];
}

@end
