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

@class GDTCOREvent;

NS_ASSUME_NONNULL_BEGIN

// TODO(ncooke3): Consider renaming to `GDTCORMetricsDroppedEventCounter`.
/// A counter object that tracks, per log source, the number of events dropped for a variety of
/// reasons. An event is considered "dropped" when the event is no longer persisted by the SDK.
@interface GDTCOREventMetricsCounter : NSObject <NSSecureCoding>

/// Creates a dropped event counter for a collection of events that were dropped for a given reason.
/// @param events The collection of events that were dropped.
/// @param reason The reason for which given events were dropped.
+ (instancetype)counterWithEvents:(NSArray<GDTCOREvent *> *)events
                 droppedForReason:(GDTCOREventDropReason)reason;

/// This API is unavailable.
- (instancetype)init NS_UNAVAILABLE;

/// Returns a counter created by merging this counter with the given counter.
/// @param counter The given counter to merge with.
- (GDTCOREventMetricsCounter *)counterByMergingWithCounter:(GDTCOREventMetricsCounter *)counter;

@end

NS_ASSUME_NONNULL_END
