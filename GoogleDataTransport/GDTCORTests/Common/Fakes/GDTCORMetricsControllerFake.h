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

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCOREventDropReason.h"
#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORMetricsControllerProtocol.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORTargets.h"

@class FBLPromise<ResultType>;
@class GDTCOREvent;
@class GDTCORMetrics;

NS_ASSUME_NONNULL_BEGIN

@interface GDTCORMetricsControllerFake : NSObject <GDTCORMetricsControllerProtocol>

@property(nonatomic, copy, nullable) void (^onLogEventsDroppedHandler)
    (GDTCOREventDropReason reason, NSSet<GDTCOREvent *> *events);

@property(nonatomic, copy, nullable) FBLPromise<GDTCORMetrics *> * (^onGetAndResetMetricsHandler)
    (void);

@property(nonatomic, copy, nullable) void (^onOfferMetricsHandler)(GDTCORMetrics *metrics);

@property(nonatomic, copy, nullable) void (^onStorageDidDropEvent)(GDTCOREvent *event);

@property(nonatomic, copy, nullable) void (^onStorageDidRemoveExpiredEvents)
    (NSSet<GDTCOREvent *> *events);

@end

NS_ASSUME_NONNULL_END
