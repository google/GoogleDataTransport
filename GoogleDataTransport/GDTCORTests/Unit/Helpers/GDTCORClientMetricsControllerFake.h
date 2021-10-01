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

#import "GoogleDataTransport/GDTCORLibrary/ClientMetrics/GDTCORClientMetricsControllerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface GDTCORClientMetricsControllerFake : NSObject <GDTCORClientMetricsControllerProtocol>

/// Is called when `logEventsDroppedWithReason:mappingID:count:` method is called with
/// corresponding arguments.
@property(nonatomic, nullable, copy) void (^logEventsDroppedHandler)
    (GDTCOREventDropReason reason, NSString *mappingID, NSUInteger count);

/// Is called when `getMetrics` method is called. The returned promise will be returned from the
/// method.
@property(nonatomic, nullable, copy) FBLPromise<GDTCORClientMetrics *> * (^getMetricsHandler)(void);

/// Is called when `confirmSendingClientMetrics:` method is called. The returned promise will be
/// returned from the method.
@property(nonatomic, nullable, copy) FBLPromise<NSNull *> * (^confirmSendingClientMetricsHandler)
    (GDTCORClientMetrics *sentMetrics);

@end

NS_ASSUME_NONNULL_END
