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

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsMetadata.h"

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCOREventDropReason.h"
#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORPlatform.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORLogSourceMetrics.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"

@interface GDTCORMetricsMetadataTest : XCTestCase

@end

@implementation GDTCORMetricsMetadataTest

- (void)testEqualityEdgeCases {
  GDTCORMetricsMetadata *metricsMetadata1 =
      [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate distantPast]
                                            logSourceMetrics:[GDTCORLogSourceMetrics metrics]];
  GDTCORMetricsMetadata *metricsMetadata2 = metricsMetadata1;
  XCTAssert([metricsMetadata1 isEqual:metricsMetadata2]);
  XCTAssertFalse([metricsMetadata1 isEqual:@"some string"]);
  XCTAssertFalse([metricsMetadata1 isEqual:nil]);
}

- (void)testEqualObjectsHaveSameHash {
  // Given
  NSArray *events = @[
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_1" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
    [[GDTCOREvent alloc] initWithMappingID:@"log_src_2" target:kGDTCORTargetTest],
  ];

  GDTCORLogSourceMetrics *logSourceMetrics =
      [GDTCORLogSourceMetrics metricsWithEvents:events
                               droppedForReason:GDTCOREventDropReasonStorageFull];

  GDTCORMetricsMetadata *metricsMetadata1 =
      [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate distantPast]
                                            logSourceMetrics:logSourceMetrics];

  GDTCORMetricsMetadata *metricsMetadata2 =
      [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate distantPast]
                                            logSourceMetrics:logSourceMetrics];

  GDTCORMetricsMetadata *metricsMetadata3 =
      [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate distantFuture]
                                            logSourceMetrics:[GDTCORLogSourceMetrics metrics]];
  // Then
  XCTAssertEqualObjects(metricsMetadata1, metricsMetadata2);
  XCTAssertEqual(metricsMetadata1.hash, metricsMetadata2.hash);
  XCTAssertNotEqualObjects(metricsMetadata2, metricsMetadata3);
  XCTAssertNotEqual(metricsMetadata2.hash, metricsMetadata3.hash);
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

  GDTCORMetricsMetadata *metricsMetadata =
      [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate date]
                                            logSourceMetrics:logSourceMetrics];

  // When
  // - Encode the metrics metadata.
  NSError *encodeError;
  NSData *encodedMetricsMetadata = GDTCOREncodeArchive(metricsMetadata, nil, &encodeError);
  XCTAssertNil(encodeError);
  XCTAssertNotNil(encodedMetricsMetadata);

  // - Write it to disk.
  NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"metadata.dat"];
  NSError *writeError;
  BOOL writeResult = GDTCORWriteDataToFile(encodedMetricsMetadata, filePath, &writeError);
  XCTAssertNil(writeError);
  XCTAssertTrue(writeResult);

  // Then
  // - Decode the metrics metadata from disk.
  NSError *decodeError;
  GDTCORMetricsMetadata *decodedMetricsMetadata =
      (GDTCORMetricsMetadata *)GDTCORDecodeArchiveAtPath(GDTCORMetricsMetadata.class, filePath,
                                                         &decodeError);
  XCTAssertNil(decodeError);
  XCTAssertNotNil(decodedMetricsMetadata);
  XCTAssertEqualObjects(decodedMetricsMetadata, metricsMetadata);
}

- (void)testSecureCoding_WhenEncodingIsCorrupted {
  // Given
  // - Create an invalid instance and write its encoding to a file. When
  //   decoding, the invalid encoding should be treated as a corrupt encoding.
  GDTCORMetricsMetadata *corruptedMetadata =
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
      [GDTCORMetricsMetadata metadataWithCollectionStartDate:@"date"
                                            logSourceMetrics:[GDTCORLogSourceMetrics metrics]];
#pragma clang diagnostic pop

  NSError *encodeError;
  NSData *encodedMetricsMetadata = GDTCOREncodeArchive(corruptedMetadata, nil, &encodeError);
  XCTAssertNil(encodeError);
  XCTAssertNotNil(encodedMetricsMetadata);

  NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"metadata.dat"];
  NSError *writeError;
  BOOL writeResult = GDTCORWriteDataToFile(encodedMetricsMetadata, filePath, &writeError);
  XCTAssertNil(writeError);
  XCTAssertTrue(writeResult);

  // When
  NSError *decodeError;
  GDTCORMetricsMetadata *decodedMetricsMetadata =
      (GDTCORMetricsMetadata *)GDTCORDecodeArchiveAtPath(GDTCORMetricsMetadata.class, filePath,
                                                         &decodeError);
  // Then
  XCTAssertNotNil(decodeError);
  XCTAssertNil(decodedMetricsMetadata);
}

@end
