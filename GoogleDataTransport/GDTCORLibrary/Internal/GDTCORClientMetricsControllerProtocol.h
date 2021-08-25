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

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCOREventDropReason.h"

NS_ASSUME_NONNULL_BEGIN

@class GDTCORClientMetrics;

@protocol GDTCORClientMetricsLogger <NSObject>

- (void)logEventDroppedWithReason:(GDTCOREventDropReason)reason;

@end


typedef void(^GDTCORClientMetricsBlock)(GDTCORClientMetrics * _Nullable metrics);

@protocol GDTCORClientMetricsControllerProtocol <GDTCORClientMetricsLogger>

- (void)logEventDroppedWithReason:(GDTCOREventDropReason)reason;

- (void)metricWithCompletion:(GDTCORClientMetricsBlock)completion;

/// Reset only specific metrics to avoid resetting metrics that has not been sent yet.
- (void)resetClientMetrics:(GDTCORClientMetrics *)metricsToReset;

@end

NS_ASSUME_NONNULL_END
