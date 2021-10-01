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

#import "GoogleDataTransport/GDTCORTests/Unit/Helpers/GDTCORClientMetricsControllerFake.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation GDTCORClientMetricsControllerFake

- (void)logEventsDroppedWithReason:(GDTCOREventDropReason)reason
                         mappingID:(NSString *)mappingID
                             count:(NSUInteger)count {
  if (self.logEventsDroppedHandler) {
    self.logEventsDroppedHandler(reason, mappingID, count);
  } else {
    [self doesNotRecognizeSelector:_cmd];
  }
}

- (FBLPromise<GDTCORClientMetrics *> *)getMetrics {
  if (self.getMetricsHandler) {
    return self.getMetricsHandler();
  } else {
    [self doesNotRecognizeSelector:_cmd];
    return [FBLPromise resolvedWith:nil];
  }
}

- (FBLPromise<NSNull *> *)confirmSendingClientMetrics:(GDTCORClientMetrics *)sentMetrics {
  if (self.confirmSendingClientMetricsHandler) {
    return self.confirmSendingClientMetricsHandler(sentMetrics);
  } else {
    [self doesNotRecognizeSelector:_cmd];
    return [FBLPromise resolvedWith:nil];
  }
}

@end

NS_ASSUME_NONNULL_END
