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

@class FBLPromise<ResultType>;
@class GDTCORClientMetrics;

/// A client metrics logger API.
@protocol GDTCORClientMetricsLogger <NSObject>

/// Logs a number of events dropped for a specified reason and mapping ID.
/// @param reason The reason why events were dropped
/// @param mappingID The mappingID (log source).
/// @param count The number of dropped events with specified reason and count.
- (void)logEventsDroppedWithReason:(GDTCOREventDropReason)reason
                         mappingID:(NSString *)mappingID
                             count:(NSUInteger)count;

@end

/// Client metrics controller API
@protocol GDTCORClientMetricsControllerProtocol <GDTCORClientMetricsLogger>

/// Retrieves metrics collected since the last metrics upload.
/// NOTE: the metrics are not reset until `confirmSendingClientMetrics:` method is called. We assume
/// that upload doesn't happen concurrently, so no data race is expected.
/// @return A promise that is fulfilled with the collected client metrics.
- (FBLPromise<GDTCORClientMetrics *> *)getMetrics;

/// Resets the sent metrics and updates last sent date.
/// @return A promise that is fulfilled when the metrics has been successfully updated.
- (FBLPromise<NSNull *> *)confirmSendingClientMetrics:(GDTCORClientMetrics *)sentMetrics;

@end

NS_ASSUME_NONNULL_END
