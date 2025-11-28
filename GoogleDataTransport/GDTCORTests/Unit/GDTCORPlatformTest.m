/*
 * Copyright 2020 Google LLC
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

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORPlatform.h"
#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORReachability.h"

#import "GoogleDataTransport/GDTCORTests/Unit/GDTCORTestCase.h"

@interface GDTCORPlatformTest : GDTCORTestCase

@end

@implementation GDTCORPlatformTest

/** Tests the reachability of mobile network connection in current platform. */
- (void)testMobileConnectionReachability {
  SCNetworkReachabilityFlags reachabilityFlags;
  XCTAssertNoThrow(reachabilityFlags = [GDTCORReachability currentFlags]);
  XCTAssertNotEqual(reachabilityFlags, 0);
  // The mobile network connection should be always false in simulator logic test.
  XCTAssertFalse(GDTCORReachabilityFlagsContainWWAN(reachabilityFlags));
}

/** Tests network connection type message generating in current platform. */
- (void)testGetNetworkConnectionType {
  NSInteger networkConnectionType;
  XCTAssertNoThrow(networkConnectionType = GDTCORNetworkTypeMessage());
  // The network connection type should be always WIFI in simulator logic test.
  XCTAssertEqual(networkConnectionType, GDTCORNetworkTypeWIFI);
}

/** Tests mobile network connection subtype generating in current platform. */
- (void)testGetNetworkMobileSubtype {
  NSInteger networkMobileSubtype;
  XCTAssertNoThrow(networkMobileSubtype = GDTCORNetworkMobileSubTypeMessage());
  // The network connection moblie subtype should be always UNKNOWN in simulator logic test.
  XCTAssertEqual(networkMobileSubtype, GDTCORNetworkMobileSubtypeUNKNOWN);
}

/** Tests the designated initializer of GDTCORApplication. */
- (void)testInitializeGDTCORApplication {
  GDTCORApplication *application;
  XCTAssertNoThrow(application = [[GDTCORApplication alloc] init]);
  XCTAssertNotNil(application);
  XCTAssertFalse(application.isRunningInBackground);
}

/** Tests the sharedApplication generating of GDTCORApplication. */
- (void)testGenerateSharedGDTCORApplication {
  GDTCORApplication *application;
  XCTAssertNoThrow(application = [GDTCORApplication sharedApplication]);
  XCTAssertNotNil(application);
}

/** Tests background task creating of GDTCORApplication. */
- (void)testGDTCORApplicationBeginBackgroundTask {
  GDTCORApplication *application;
  application = [[GDTCORApplication alloc] init];
  __block GDTCORBackgroundIdentifier bgID;
  XCTAssertNoThrow(bgID = [application beginBackgroundTaskWithName:@"GDTCORPlatformTest"
                                                 expirationHandler:^{
                                                   [application endBackgroundTask:bgID];
                                                   bgID = GDTCORBackgroundIdentifierInvalid;
                                                 }]);
  XCTAssertNoThrow([application endBackgroundTask:bgID]);
}

- (void)testGDTCORWriteDataToFile {
  NSString *directoryPath =
      [NSTemporaryDirectory() stringByAppendingPathComponent:@"testGDTCORWriteDataToFile"];
  NSString *filePath = [directoryPath stringByAppendingPathComponent:@"testFile.txt"];
  NSData *data = [@"testData" dataUsingEncoding:NSUTF8StringEncoding];

  // Clean up any old test artifacts.
  [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:nil];

  // Write the data to the file.
  NSError *error;
  XCTAssertTrue(GDTCORWriteDataToFile(data, filePath, &error));
  XCTAssertNil(error);

  // Verify that the file was created and contains the correct data.
  NSData *readData = [NSData dataWithContentsOfFile:filePath];
  XCTAssertEqualObjects(data, readData);

  // Clean up the test artifacts.
  [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:nil];
}

@end
