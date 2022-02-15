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

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCOREventMetricsCounter.h"

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"

typedef NSDictionary<NSNumber *, NSNumber *> GDTCORDroppedEventCounter;

@interface GDTCOREventMetricsCounter ()

// TODO(ncooke3): Document.
@property(nonatomic)
    NSDictionary<NSString *, GDTCORDroppedEventCounter *> *droppedEventCounterByMappingID;

@end

@implementation GDTCOREventMetricsCounter

+ (instancetype)counterWithEvents:(NSArray<GDTCOREvent *> *)events
                 droppedForReason:(GDTCOREventDropReason)reason {
  NSMutableDictionary<NSString *, GDTCORDroppedEventCounter *> *eventCounterByMappingID =
      [NSMutableDictionary dictionary];

  for (GDTCOREvent *event in events) {
    // TODO(ncooke3): Should I use an autorelease pool?
    // Dropped events with a `nil` or empty mapping ID (log source) are not recorded.
    if ([event.mappingID length] == 0) {
      continue;
    }

    // Get the dropped event counter for the event's mapping ID (log source).
    // If there the dropped event counter for this event's mapping ID is `nil`,
    // an empty mutable counter is returned.
    NSMutableDictionary<NSNumber *, NSNumber *> *eventCounter =
        [NSMutableDictionary dictionaryWithDictionary:eventCounterByMappingID[event.mappingID]];

    // Increment the dropped event counter for the given reason.
    NSInteger currentEventCountForReason = [eventCounter[@(reason)] integerValue];
    NSInteger updatedEventCountForReason = currentEventCountForReason + 1;

    eventCounter[@(reason)] = @(updatedEventCountForReason);

    // Update the mapping ID's (log source's) event counter with an immutable
    // copy of the updated counter.
    eventCounterByMappingID[event.mappingID] = [eventCounter copy];
  }

  return [[self alloc] initWithDroppedEventCounterByMappingID:[eventCounterByMappingID copy]];
}

- (instancetype)initWithDroppedEventCounterByMappingID:
    (NSDictionary<NSString *, GDTCORDroppedEventCounter *> *)droppedEventCounterByMappingID {
  self = [super init];
  if (self) {
    _droppedEventCounterByMappingID = droppedEventCounterByMappingID;
  }
  return self;
}

- (GDTCOREventMetricsCounter *)counterByMergingWithCounter:(GDTCOREventMetricsCounter *)counter {
  // TODO(ncooke3): Add clarifying comment.
  // TODO(ncooke3): Optimize the ordering of `droppedEventCounterByMappingID` passed in.
  NSDictionary<NSString *, GDTCORDroppedEventCounter *> *mergedEventCounterByMappingID = [[self
      class] dictionaryByMergingDictionary:self.droppedEventCounterByMappingID
                       withOtherDictionary:counter.droppedEventCounterByMappingID
                     uniquingKeysWithBlock:^NSDictionary *(NSDictionary *eventCounter1,
                                                           NSDictionary *eventCounter2) {
                       return [[self class]
                           dictionaryByMergingDictionary:eventCounter1
                                     withOtherDictionary:eventCounter2
                                   uniquingKeysWithBlock:^NSNumber *(NSNumber *eventCount1,
                                                                     NSNumber *eventCount2) {
                                     return @(eventCount1.integerValue + eventCount2.integerValue);
                                   }];
                     }];

  return
      [[[self class] alloc] initWithDroppedEventCounterByMappingID:mergedEventCounterByMappingID];
}

// TODO(ncooke3): Document.
+ (NSDictionary *)dictionaryByMergingDictionary:(NSDictionary *)dictionary
                            withOtherDictionary:(NSDictionary *)otherDictionary
                          uniquingKeysWithBlock:(id (^)(id value1, id value2))block {
  NSMutableDictionary *mergedDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];

  [otherDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    if (mergedDictionary[key] != nil) {
      // TODO(ncooke3): Add clarifying comment.
      id newValue = block(mergedDictionary[key], obj);
      mergedDictionary[key] = newValue;
    } else {
      mergedDictionary[key] = obj;
    }
  }];

  return [mergedDictionary copy];
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
