// Copyright 2023 Google LLC
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

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORProductData.h"

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORPlatform.h"

@interface GDTCORProductDataTest : GDTCORTestCase

@end

@implementation GDTCORProductDataTest

static int32_t kTestProductID = 123456;

- (void)testInit {
  GDTCORProductData *productData = [[GDTCORProductData alloc] initWithProductID:kTestProductID];
  XCTAssertEqual(productData.productID, kTestProductID);
}

- (void)testCopy {
  GDTCORProductData *productData = [[GDTCORProductData alloc] initWithProductID:kTestProductID];
  XCTAssertEqualObjects([productData copy], productData);
}

- (void)testIsEqualAndHash {
  GDTCORProductData *productData1 = [[GDTCORProductData alloc] initWithProductID:0000];
  GDTCORProductData *productData2 = [[GDTCORProductData alloc] initWithProductID:0000];
  GDTCORProductData *productData3 = [[GDTCORProductData alloc] initWithProductID:1111];

  XCTAssertEqualObjects(productData1, productData2);
  XCTAssertNotEqualObjects(productData1, productData3);

  XCTAssertEqual(productData1.hash, productData2.hash);
  XCTAssertNotEqual(productData1.hash, productData3.hash);
}

- (void)testSecureCoding {
  // Given
  GDTCORProductData *productData = [[GDTCORProductData alloc] initWithProductID:kTestProductID];

  // When
  // - Encode.
  NSError *encodeError;
  NSData *encodedProductData = GDTCOREncodeArchive(productData, nil, &encodeError);
  XCTAssertNil(encodeError);
  XCTAssertNotNil(encodedProductData);

  // - Write to disk.
  NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"productdata.dat"];
  NSError *writeError;
  BOOL writeResult = GDTCORWriteDataToFile(encodedProductData, filePath, &writeError);
  XCTAssertNil(writeError);
  XCTAssertTrue(writeResult);

  // Then
  // - Decode from disk.
  NSError *decodeError;
  GDTCORProductData *decodedProductData = (GDTCORProductData *)GDTCORDecodeArchiveAtPath(
      GDTCORProductData.class, filePath, &decodeError);
  XCTAssertNil(decodeError);
  XCTAssertNotNil(decodedProductData);
  XCTAssertEqualObjects(decodedProductData, productData);
}

@end
