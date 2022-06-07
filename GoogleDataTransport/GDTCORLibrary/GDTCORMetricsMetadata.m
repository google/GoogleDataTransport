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

#import <Foundation/Foundation.h>

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsMetadata.h"

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCOREventMetricsCounter.h"

static NSString *const kCollectionStartDate = @"collectionStartDate";
static NSString *const kDroppedEventCounter = @"droppedEventCounter";

@implementation GDTCORMetricsMetadata

+ (instancetype)metadataWithCollectionStartDate:(NSDate *)collectedSinceDate
                            eventMetricsCounter:(GDTCOREventMetricsCounter *)eventMetricsCounter {
  return [[self alloc] initWithCollectionStartDate:collectedSinceDate counter:eventMetricsCounter];
}

- (instancetype)initWithCollectionStartDate:(NSDate *)collectionStartDate
                                    counter:(GDTCOREventMetricsCounter *)counter {
  self = [super init];
  if (self) {
    _collectionStartDate = [collectionStartDate copy];
    _droppedEventCounter = counter;
  }
  return self;
}

#pragma mark - Equality

- (BOOL)isEqualToMetricsMetadata:(GDTCORMetricsMetadata *)otherMetricsMetadata {
  return [self.collectionStartDate isEqualToDate:otherMetricsMetadata.collectionStartDate] &&
         [self.droppedEventCounter
             isEqualToDroppedEventCounter:otherMetricsMetadata.droppedEventCounter];
}

- (BOOL)isEqual:(nullable id)object {
  if (object == nil) {
    return NO;
  }

  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  return [self isEqualToMetricsMetadata:(GDTCORMetricsMetadata *)object];
}

- (NSUInteger)hash {
  return [self.collectionStartDate hash] ^ [self.droppedEventCounter hash];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
  NSDate *collectionStartDate = [coder decodeObjectOfClass:[NSDate class]
                                                    forKey:kCollectionStartDate];
  GDTCOREventMetricsCounter *droppedEventCounter =
      [coder decodeObjectOfClass:[GDTCOREventMetricsCounter class] forKey:kDroppedEventCounter];

  if (!collectionStartDate || !droppedEventCounter ||
      ![collectionStartDate isKindOfClass:[NSDate class]] ||
      ![droppedEventCounter isKindOfClass:[GDTCOREventMetricsCounter class]]) {
    // If any of the fields are corrupted, the initializer should fail.
    return nil;
  }

  return [self initWithCollectionStartDate:collectionStartDate counter:droppedEventCounter];
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
  [coder encodeObject:self.collectionStartDate forKey:kCollectionStartDate];
  [coder encodeObject:self.droppedEventCounter forKey:kDroppedEventCounter];
}

@end
