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

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORStorageSizeBytes.h"

@class GDTCORDroppedEventsCounter;

NS_ASSUME_NONNULL_BEGIN

/// A data model to keep and pass client metrics.
@interface GDTCORClientMetrics : NSObject

/// The date when the metrics collection started.
@property(nonatomic, readonly) NSDate *collectedSinceDate;

/// Number of bytes currently used by the storage for events and batches.
@property(nonatomic, readonly) GDTCORStorageSizeBytes currentStorageSize;

/// Maximum number of bytes that is allowed to be used by the storage for events and batches.
@property(nonatomic, readonly) GDTCORStorageSizeBytes maximumStorageSize;

/// Dropped event counters.
@property(nonatomic, readonly)
    NSDictionary<NSString *, NSArray<GDTCORDroppedEventsCounter *> *> *droppedEventsByMappingID;

- (instancetype)init NS_UNAVAILABLE;

/// Designated initializer. See corresponding property docs for details.
- (instancetype)initWithCurrentStorageSize:(GDTCORStorageSizeBytes)currentStorageSize
                        maximumStorageSize:(GDTCORStorageSizeBytes)maximumStorageSize
                  droppedEventsByMappingID:
                      (NSDictionary<NSString *, NSArray<GDTCORDroppedEventsCounter *> *> *)
                          droppedEventsByMappingID NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
