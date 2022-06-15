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

- (nonnull FBLPromise<GDTCORMetrics *> *)getAndResetMetrics {
  if (self.onGetAndResetMetricsHandler) {
    return self.onGetAndResetMetricsHandler();
  } else {
    [self doesNotRecognizeSelector:_cmd];
    return [FBLPromise resolvedWith:nil];
  }
}

- (FBLPromise<NSNull *> *)offerMetrics:(GDTCORMetrics *)metrics {
  if (self.onOfferMetricsHandler) {
    self.onOfferMetricsHandler(metrics);
  } else {
    [self doesNotRecognizeSelector:_cmd];
  }
  return [FBLPromise resolvedWith:nil];
}

- (void)storage:(id<GDTCORStoragePromiseProtocol>)storage didDropEvent:(GDTCOREvent *)event {
  if (self.onStorageDidDropEvent) {
    return self.onStorageDidDropEvent(event);
  } else {
    [self doesNotRecognizeSelector:_cmd];
  }
}

- (void)storage:(nonnull id<GDTCORStorageProtocol>)storage
    didRemoveExpiredEvents:(nonnull NSSet<GDTCOREvent *> *)events {
  if (self.onStorageDidRemoveExpiredEvents) {
    return self.onStorageDidRemoveExpiredEvents(events);
  } else {
    [self doesNotRecognizeSelector:_cmd];
  }
}

@end
