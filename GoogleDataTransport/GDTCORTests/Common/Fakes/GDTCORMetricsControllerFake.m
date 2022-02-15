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

#import "GoogleDataTransport/GDTCORTests/Common/Fakes/GDTCORMetricsControllerFake.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

@implementation GDTCORMetricsControllerFake

- (FBLPromise<NSNull *> *)logEventsDroppedForReason:(GDTCOREventDropReason)reason
                                             events:(NSSet<GDTCOREvent *> *)events {
  if (self.onLogEventsDroppedHandler) {
    self.onLogEventsDroppedHandler(reason, events);
  } else {
    [self doesNotRecognizeSelector:_cmd];
  }
  return [FBLPromise resolvedWith:nil];
}

- (FBLPromise<GDTCORMetrics *> *)fetchMetrics {
  if (self.onFetchMetricsHandler) {
    return self.onFetchMetricsHandler();
  } else {
    [self doesNotRecognizeSelector:_cmd];
    return [FBLPromise resolvedWith:nil];
  }
}

- (FBLPromise<NSNull *> *)confirmMetrics:(GDTCORMetrics *)metrics wereUploaded:(BOOL)uploaded {
  if (self.onConfirmMetricsHandler) {
    self.onConfirmMetricsHandler(metrics, uploaded);
  } else {
    [self doesNotRecognizeSelector:_cmd];
  }
  return [FBLPromise resolvedWith:nil];
}

- (BOOL)isMetricsCollectionSupportedForTarget:(GDTCORTarget)target {
  if (self.onTargetSupportsMetricsCollectionHandler) {
    return self.onTargetSupportsMetricsCollectionHandler(target);
  } else {
    [self doesNotRecognizeSelector:_cmd];
    return NO;
  }
}

- (void)storage:(id<GDTCORStoragePromiseProtocol>)storage
    didRemoveExpiredEvent:(GDTCOREvent *)event {
  // TODO(ncooke3): Implement.
}

- (void)storage:(id<GDTCORStoragePromiseProtocol>)storage didDropEvent:(GDTCOREvent *)event {
  // TODO(ncooke3): Implement.
}

@end
