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

#import <XCTest/XCTest.h>

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORDirectorySizeTracker.h"

@interface GDTCORDirectorySizeTrackerTests : XCTestCase

@end

@implementation GDTCORDirectorySizeTrackerTests

- (void)testDirectoryContentSizeDoesNotCrashWhenDirectoryPathContainsWhitespaces {
  NSString *pathWithSpaces = [NSTemporaryDirectory() stringByAppendingPathComponent:@"some dir"];
  GDTCORDirectorySizeTracker *tracker =
      [[GDTCORDirectorySizeTracker alloc] initWithDirectoryPath:pathWithSpaces];

  XCTAssertNoThrow([tracker directoryContentSize]);
}

- (void)testDirectoryContentSizeReturnsZeroWhenError {
  // Given
  NSString *dir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"a"];
  [[NSFileManager defaultManager] createDirectoryAtPath:dir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];
  GDTCORDirectorySizeTracker *sut = [[GDTCORDirectorySizeTracker alloc] initWithDirectoryPath:dir];
  [[NSFileManager defaultManager] removeItemAtPath:dir error:nil];

  // When
  GDTCORStorageSizeBytes size = [sut directoryContentSize];

  // Then
  XCTAssertEqual(size, 0);
}

@end
