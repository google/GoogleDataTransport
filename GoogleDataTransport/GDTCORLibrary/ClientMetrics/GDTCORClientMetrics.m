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

#import "GoogleDataTransport/GDTCORLibrary/ClientMetrics/GDTCORClientMetrics.h"

NS_ASSUME_NONNULL_BEGIN

@implementation GDTCORClientMetrics

- (instancetype)initWithCurrentStorageSize:(GDTCORStorageSizeBytes)currentStorageSize
                        maximumStorageSize:(GDTCORStorageSizeBytes)maximumStorageSize
                  droppedEventsByMappingID:(NSDictionary<NSString *, NSArray<GDTCORDroppedEventsCounter *> *> *)droppedEventsByMappingID {
  self = [super init];
  if (self) {
    _currentStorageSize = currentStorageSize;
    _maximumStorageSize = maximumStorageSize;
    _droppedEventsByMappingID = [droppedEventsByMappingID copy];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
