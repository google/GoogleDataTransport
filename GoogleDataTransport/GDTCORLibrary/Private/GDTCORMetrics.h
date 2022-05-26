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

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREventDataObject.h"

@class GDTCOREventMetricsCounter;
@class GDTCORMetricsMetadata;
@class GDTCORStorageMetadata;

NS_ASSUME_NONNULL_BEGIN

/// An object representing metrics that represent a snapshot of the SDK's state and performance.
@interface GDTCORMetrics : NSObject <GDTCOREventDataObject>

/// The start of the time window over which the metrics were collected.
@property(nonatomic, readonly) NSDate *collectionStartDate;

/// The dropped event counter associated with the metrics.
@property(nonatomic, readonly) GDTCOREventMetricsCounter *droppedEventCounter;

/// Creates a metrics instance with the provided metadata.
/// @param metricsMetadata The provided metrics metadata.
/// @param storageMetadata The provided storage metadata.
+ (instancetype)metricsWithMetricsMetadata:(GDTCORMetricsMetadata *)metricsMetadata
                           storageMetadata:(GDTCORStorageMetadata *)storageMetadata;

@end

NS_ASSUME_NONNULL_END
