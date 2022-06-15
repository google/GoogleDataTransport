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

#import "GoogleDataTransport/GDTCCTTests/Unit/Helpers/GDTCORMetricsTestHelpers.h"

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORLogSourceMetrics.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetrics.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsMetadata.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORStorageMetadata.h"

#pragma mark - GDTCORLogSourceMetrics + Internal

typedef NSDictionary<NSNumber *, NSNumber *> GDTCORDroppedEventCounter;

@interface GDTCORLogSourceMetrics (Internal)

/// Initializer exposed for testing.
- (instancetype)initWithDroppedEventCounterByLogSource:
    (NSDictionary<NSString *, GDTCORDroppedEventCounter *> *)droppedEventCounterByLogSource;

@end

#pragma mark - GDTCORMetrics + Internal

@interface GDTCORMetrics (Internal)

/// Initializer exposed for testing.
- (instancetype)initWithCollectionStartDate:(NSDate *)collectionStartDate
                          collectionEndDate:(NSDate *)collectionEndDate
                           logSourceMetrics:(GDTCORLogSourceMetrics *)logSourceMetrics
                           currentCacheSize:(GDTCORStorageSizeBytes)currentCacheSize
                               maxCacheSize:(GDTCORStorageSizeBytes)maxCacheSize
                                   bundleID:(NSString *)bundleID;
@end

#pragma mark - GDTCORMetricsTestHelpers

@implementation GDTCORMetricsTestHelpers

+ (GDTCORMetrics *)metricsWithGeneratedDroppedEventCounters {
  // The below counter's structure was arbitrarily defined.
  GDTCORLogSourceMetrics *logSourceMetrics =
      [[GDTCORLogSourceMetrics alloc] initWithDroppedEventCounterByLogSource:@{
        @"log_src_1" : @{@(GDTCOREventDropReasonUnknown) : @(arc4random_uniform(5))},
        @"log_src_2" : @{
          @(GDTCOREventDropReasonStorageFull) : @(arc4random_uniform(100)),
          @(GDTCOREventDropReasonServerError) : @(arc4random_uniform(100)),
        },
        @"log_src_3" : @{
          @(GDTCOREventDropReasonUnknown) : @(arc4random_uniform(10)),
          @(GDTCOREventDropReasonStorageFull) : @(arc4random_uniform(10)),
          @(GDTCOREventDropReasonServerError) : @(arc4random_uniform(10)),
          @(GDTCOREventDropReasonMessageTooOld) : @(arc4random_uniform(10)),
          @(GDTCOREventDropReasonPayloadTooBig) : @(arc4random_uniform(10)),
          @(GDTCOREventDropReasonInvalidPayload) : @(arc4random_uniform(10)),
          @(GDTCOREventDropReasonMaxRetriesReached) : @(arc4random_uniform(10)),
        },
      }];

  return [[GDTCORMetrics alloc] initWithCollectionStartDate:[NSDate distantPast]
                                          collectionEndDate:[NSDate distantFuture]
                                           logSourceMetrics:logSourceMetrics
                                           currentCacheSize:arc4random_uniform(20 * 1000 * 1000)
                                               maxCacheSize:arc4random_uniform(20 * 1000 * 1000)
                                                   bundleID:@"com.test.bundle"];
}

+ (GDTCORMetrics *)metricsWithEmptyDroppedEventCounters {
  return [[GDTCORMetrics alloc] initWithCollectionStartDate:[NSDate distantPast]
                                          collectionEndDate:[NSDate distantFuture]
                                           logSourceMetrics:[GDTCORLogSourceMetrics metrics]
                                           currentCacheSize:arc4random_uniform(20 * 1000 * 1000)
                                               maxCacheSize:arc4random_uniform(20 * 1000 * 1000)
                                                   bundleID:@"com.test.bundle"];
}

+ (void)assertMetrics:(GDTCORMetrics *)metrics
    correspondToProto:(gdt_client_metrics_ClientMetrics)metricsProto {
  GDTCORMetrics *metricsFromProto = GDTCCTConvertMetricsProtoToGDTCORMetrics(metricsProto);
  XCTAssertEqualObjects(metrics, metricsFromProto);
}

GDTCORMetrics *GDTCCTConvertMetricsProtoToGDTCORMetrics(
    gdt_client_metrics_ClientMetrics metricsProto) {
  // Reconstruct dates.
  NSDate *collectionStartDate =
      [[NSDate alloc] initWithTimeIntervalSince1970:metricsProto.window.start_ms / 1000];

  NSDate *collectionEndDate =
      [[NSDate alloc] initWithTimeIntervalSince1970:metricsProto.window.end_ms / 1000];

  // Reconstruct log source metrics.
  GDTCORLogSourceMetrics *logSourceMetrics = [GDTCORLogSourceMetrics metrics];

  for (int logSourceIndex = 0; logSourceIndex < metricsProto.log_source_metrics_count;
       logSourceIndex++) {
    gdt_client_metrics_LogSourceMetrics logSourceMetricsProto =
        metricsProto.log_source_metrics[logSourceIndex];

    NSString *logSource = [[NSString alloc] initWithBytes:logSourceMetricsProto.log_source->bytes
                                                   length:logSourceMetricsProto.log_source->size
                                                 encoding:NSUTF8StringEncoding];

    for (int logEventIndex = 0; logEventIndex < logSourceMetricsProto.log_event_dropped_count;
         logEventIndex++) {
      gdt_client_metrics_LogEventDropped logEventDropped =
          logSourceMetricsProto.log_event_dropped[logEventIndex];

      GDTCORLogSourceMetrics *logSourceDroppedEventCounter =
          [[GDTCORLogSourceMetrics alloc] initWithDroppedEventCounterByLogSource:@{
            logSource : @{
              @(GDTCCTConvertProtoReasonToEventDropReason(logEventDropped.reason)) :
                  @(logEventDropped.events_dropped_count),
            },
          }];

      logSourceMetrics = [logSourceMetrics
          logSourceMetricsByMergingWithLogSourceMetrics:logSourceDroppedEventCounter];
    }
  }

  // Reconstruct storage metadata.
  GDTCORStorageSizeBytes currentCacheSize =
      metricsProto.global_metrics.storage_metrics.current_cache_size_bytes;

  GDTCORStorageSizeBytes maxCacheSize =
      metricsProto.global_metrics.storage_metrics.max_cache_size_bytes;

  // Reconstruct bundle ID.
  NSString *bundleID = [[NSString alloc] initWithBytes:metricsProto.app_namespace->bytes
                                                length:metricsProto.app_namespace->size
                                              encoding:NSUTF8StringEncoding];

  return [[GDTCORMetrics alloc] initWithCollectionStartDate:collectionStartDate
                                          collectionEndDate:collectionEndDate
                                           logSourceMetrics:logSourceMetrics
                                           currentCacheSize:currentCacheSize
                                               maxCacheSize:maxCacheSize
                                                   bundleID:bundleID];
}

/// Returns the corresponding ``GDTCOREventDropReason`` for the given
/// ``gdt_client_metrics_LogEventDropped_Reason``.
/// @param protoReason The ``gdt_client_metrics_LogEventDropped_Reason`` to represent as
/// a ``GDTCOREventDropReason``.
GDTCOREventDropReason GDTCCTConvertProtoReasonToEventDropReason(
    gdt_client_metrics_LogEventDropped_Reason protoReason) {
  switch (protoReason) {
    case gdt_client_metrics_LogEventDropped_Reason_REASON_UNKNOWN:
      return GDTCOREventDropReasonUnknown;
    case gdt_client_metrics_LogEventDropped_Reason_MESSAGE_TOO_OLD:
      return GDTCOREventDropReasonMessageTooOld;
    case gdt_client_metrics_LogEventDropped_Reason_CACHE_FULL:
      return GDTCOREventDropReasonStorageFull;
    case gdt_client_metrics_LogEventDropped_Reason_PAYLOAD_TOO_BIG:
      return GDTCOREventDropReasonPayloadTooBig;
    case gdt_client_metrics_LogEventDropped_Reason_MAX_RETRIES_REACHED:
      return GDTCOREventDropReasonMaxRetriesReached;
    // The below typo (`PAYLOD`) is currently checked in to g3.
    case gdt_client_metrics_LogEventDropped_Reason_INVALID_PAYLOD:
      return GDTCOREventDropReasonInvalidPayload;
    case gdt_client_metrics_LogEventDropped_Reason_SERVER_ERROR:
      return GDTCOREventDropReasonServerError;
  }
}

@end
