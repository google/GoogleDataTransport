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

#import <Foundation/Foundation.h>

#import "GoogleDataTransport/GDTCORLibrary/ClientMetrics/GDTCOREventDropReason.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents a number of events dropped for a particular mapping ID with a specified reason.
/// The model is also used as a stored object for the persistent storage.
@interface GDTCORDroppedEventsCounter : NSObject <NSSecureCoding>

/// Number of events dropped.
@property(nonatomic, readonly) NSUInteger eventCount;

/// The reason why the events were dropped.
@property(nonatomic, readonly) GDTCOREventDropReason dropReason;

/// The dropped events mapping ID, also called a log source.
@property(nonatomic, readonly) NSString *mappingID;

/// The version of the object schema. This value should be incremented each time the object property
/// are changed and handled accordingly in `initWithCoder:` method to decode archives encoded with
/// older versions correctly.
@property(nonatomic, readonly) NSUInteger storageVersion;

- (instancetype)init NS_UNAVAILABLE;

/// The default initializer. See docs for corresponding properties for the parameter details.
- (instancetype)initWithEventCount:(NSInteger)eventCount
                        dropReason:(GDTCOREventDropReason)dropReason
                         mappingID:(NSString *)mappingID;

@end

NS_ASSUME_NONNULL_END
