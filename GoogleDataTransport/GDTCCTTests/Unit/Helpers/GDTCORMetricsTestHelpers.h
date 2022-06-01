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
#import <XCTest/XCTest.h>

#include "GoogleDataTransport/GDTCCTLibrary/Protogen/nanopb/client_metrics.nanopb.h"

@class GDTCORMetrics;

NS_ASSUME_NONNULL_BEGIN

/// A test utility class that provides helpers when working with ``GDTCORMetrics`` instances.
@interface GDTCORMetricsTestHelpers : NSObject

/// Creates and returns ``GDTCORMetrics`` instance with randomly generated dropped event counters
/// and storage metadata.
+ (GDTCORMetrics *)metricsWithGeneratedDroppedEventCounters;

/// Creates and returns ``GDTCORMetrics`` instance with empty dropped event counters.
+ (GDTCORMetrics *)metricsWithEmptyDroppedEventCounters;

/// Converts the given proto to a metrics object and then uses ``XCTAssertEqualObjects`` to assert
/// that the reconstructed metrics object equals the given metrics object.
/// @param metrics A given metrics object to compare.
/// @param metricsProto The given proto to reconstruct a metrics object with for comparison.
+ (void)assertMetrics:(GDTCORMetrics *)metrics
    correspondToProto:(gdt_client_metrics_ClientMetrics)metricsProto;

@end

NS_ASSUME_NONNULL_END
