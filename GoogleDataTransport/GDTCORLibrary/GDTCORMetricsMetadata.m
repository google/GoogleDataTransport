/*
 * Copyright 2022 Google LLC
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

#import <Foundation/Foundation.h>

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsMetadata.h"

@implementation GDTCORMetricsMetadata

+ (instancetype)metadataWithCollectionStartDate:(NSDate *)collectedSinceDate
                            eventMetricsCounter:
                                (nullable GDTCOREventMetricsCounter *)eventMetricsCounter {
  return [[self alloc] initWithCollectionStartDate:collectedSinceDate counter:eventMetricsCounter];
}

- (instancetype)initWithCollectionStartDate:(NSDate *)collectionStartDate
                                    counter:(nullable GDTCOREventMetricsCounter *)counter {
  self = [super init];
  if (self) {
    _collectionStartDate = collectionStartDate;
    _droppedEventCounter = counter;
  }
  return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
  // TODO(ncooke3): Implement
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
  // TODO(ncooke3): Implement
  return nil;
}

@end
