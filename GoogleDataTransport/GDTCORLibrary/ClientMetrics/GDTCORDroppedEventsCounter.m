/*
 * Copyright 2021 Google LLC
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

#import "GoogleDataTransport/GDTCORLibrary/ClientMetrics/GDTCORDroppedEventsCounter.h"

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORConsoleLogger.h"

static const NSInteger kCurrentStorageVersion = 1;

static NSString *const kEventCountKey = @"eventCount";
static NSString *const kDropReasonKey = @"dropReason";
static NSString *const kMappingIDKey = @"mappingID";
static NSString *const kStorageVersionKey = @"storageVersion";

@implementation GDTCORDroppedEventsCounter

- (instancetype)initWithEventCount:(NSInteger)eventCount
                        dropReason:(GDTCOREventDropReason)dropReason
                         mappingID:(NSString *)mappingID {
  self = [super init];
  if (self) {
    _eventCount = eventCount;
    _dropReason = dropReason;
    _mappingID = mappingID;
  }
  return self;
}

- (NSUInteger)storageVersion {
  return kCurrentStorageVersion;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
  [coder encodeInteger:self.storageVersion forKey:kStorageVersionKey];
  [coder encodeInteger:self.eventCount forKey:kEventCountKey];
  [coder encodeInteger:self.dropReason forKey:kDropReasonKey];
  [coder encodeObject:self.mappingID forKey:kMappingIDKey];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
  NSInteger decodedStorageVersion = [coder decodeIntegerForKey:kStorageVersionKey];
  if (decodedStorageVersion > self.storageVersion) {
    GDTCORLogWarning(GDTCORMCDDebugLog,
                     @"GDTCORDroppedEventsCounter was encoded by a newer coder version %ld. "
                     @"Current coder version is %ld. Some installation data may be lost.",
                     decodedStorageVersion, (long)kCurrentStorageVersion);
  }

  // Even if the mapping ID is corrupted, we still would like to capture the dropped event with an
  // empty mapping ID.
  NSString *mappingID = [coder decodeObjectOfClass:[NSString class] forKey:kMappingIDKey] ?: @"";
  NSInteger evenCount = [coder decodeIntegerForKey:kEventCountKey];
  GDTCOREventDropReason dropReason = [coder decodeIntegerForKey:kDropReasonKey];

  return [self initWithEventCount:evenCount dropReason:dropReason mappingID:mappingID];
}

@end
