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

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCOREventDropReason.h"
#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORStorageProtocol.h"

@class FBLPromise<ResultType>;
@class GDTCOREvent;
@class GDTCORMetrics;

NS_ASSUME_NONNULL_BEGIN

// TODO(ncooke3): Document.
@protocol GDTCORMetricsControllerProtocol <GDTCORStorageDelegate>

// TODO(ncooke3): Document.
- (FBLPromise<NSNull *> *)logEventsDroppedForReason:(GDTCOREventDropReason)reason
                                             events:(NSSet<GDTCOREvent *> *)events;

// TODO(ncooke3): Document.
- (FBLPromise<GDTCORMetrics *> *)getAndResetMetrics;

// TODO(ncooke3): Document.
- (FBLPromise<NSNull *> *)confirmMetrics:(GDTCORMetrics *)metrics wereUploaded:(BOOL)uploaded;

// TODO(ncooke3): Document.
- (BOOL)isMetricsCollectionSupportedForTarget:(GDTCORTarget)target;

@end

FOUNDATION_EXPORT
id<GDTCORMetricsControllerProtocol> _Nullable GDTCORMetricsControllerInstanceForTarget(
    GDTCORTarget target);

NS_ASSUME_NONNULL_END
