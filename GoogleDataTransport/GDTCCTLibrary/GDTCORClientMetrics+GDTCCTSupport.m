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

#import "GoogleDataTransport/GDTCCTLibrary/GDTCORClientMetrics+GDTCCTSupport.h"

#import "GoogleDataTransport/GDTCCTLibrary/Private/GDTCCTNanopbHelpers.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORConsoleLogger.h"

#include "GoogleDataTransport/GDTCCTLibrary/Protogen/nanopb/client_metrics.nanopb.h"

#import "GoogleDataTransport/GDTCORLibrary/ClientMetrics/GDTCORDroppedEventsCounter.h"

#import <nanopb/pb.h>
#import <nanopb/pb_decode.h>
#import <nanopb/pb_encode.h>

@implementation GDTCORClientMetrics (GDTCCTSupport)

- (NSData *)transportBytes {
  gdt_client_metrics_ClientMetrics clientMetricsProto = [self clientMetricsProto];

  pb_ostream_t sizestream = PB_OSTREAM_SIZING;
  // Encode 1 time to determine the size.
  if (!pb_encode(&sizestream, gdt_client_metrics_ClientMetrics_fields, &clientMetricsProto)) {
    GDTCORLogError(GDTCORMCEGeneralError, @"Error in nanopb encoding for size: %s",
                   PB_GET_ERROR(&sizestream));
    return [NSData data];
  }

  // Encode a 2nd time to actually get the bytes from it.
  size_t bufferSize = sizestream.bytes_written;
  CFMutableDataRef dataRef = CFDataCreateMutable(CFAllocatorGetDefault(), bufferSize);
  CFDataSetLength(dataRef, bufferSize);
  pb_ostream_t ostream = pb_ostream_from_buffer((void *)CFDataGetBytePtr(dataRef), bufferSize);
  if (!pb_encode(&ostream, gdt_client_metrics_ClientMetrics_fields, &clientMetricsProto)) {
    GDTCORLogError(GDTCORMCEGeneralError, @"Error in nanopb encoding for bytes: %s",
                   PB_GET_ERROR(&ostream));
  }

  // Release all allocated protos.
  pb_release(gdt_client_metrics_ClientMetrics_fields, &clientMetricsProto);

  return CFBridgingRelease(dataRef);
}

- (gdt_client_metrics_ClientMetrics)clientMetricsProto {
  __block gdt_client_metrics_ClientMetrics clientMetrics =
      gdt_client_metrics_ClientMetrics_init_default;

  // App namespace.
  clientMetrics.app_namespace = GDTCCTEncodeString([NSBundle mainBundle].bundleIdentifier);

  // Global metrics.
  gdt_client_metrics_StorageMetrics storageMetrics = gdt_client_metrics_StorageMetrics_init_zero;
  storageMetrics.current_cache_size_bytes = self.currentStorageSize;
  storageMetrics.max_cache_size_bytes = self.maximumStorageSize;

  gdt_client_metrics_GlobalMetrics globalMetrics = gdt_client_metrics_GlobalMetrics_init_zero;
  globalMetrics.storage_metrics = storageMetrics;

  // Log source metrics (metrics for a specific mapping ID).
  if (self.droppedEventsByMappingID.count < 1) {
    return clientMetrics;
  }

  NSUInteger logMetricsCount = self.droppedEventsByMappingID.count;
  clientMetrics.log_source_metrics =
      calloc(logMetricsCount, sizeof(gdt_client_metrics_LogSourceMetrics));
  clientMetrics.log_source_metrics_count = (pb_size_t)logMetricsCount;

  __block NSUInteger logSourceIndex = 0;
  [self.droppedEventsByMappingID
      enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull mappingID,
                                          NSArray<GDTCORDroppedEventsCounter *> *_Nonnull counters,
                                          BOOL *_Nonnull stop) {
        __block gdt_client_metrics_LogSourceMetrics logMetrics =
            gdt_client_metrics_LogSourceMetrics_init_zero;
        logMetrics.log_source = GDTCCTEncodeString(mappingID);
        logMetrics.log_event_dropped =
            calloc(counters.count, sizeof(gdt_client_metrics_LogEventDropped));
        logMetrics.log_event_dropped_count = (pb_size_t)counters.count;

        [counters enumerateObjectsUsingBlock:^(GDTCORDroppedEventsCounter *_Nonnull counter,
                                               NSUInteger idx, BOOL *_Nonnull stop) {
          logMetrics.log_event_dropped[idx] = [self logEventDroppedWithCounter:counter];
        }];

        clientMetrics.log_source_metrics[logSourceIndex] = logMetrics;

        logSourceIndex += 1;
      }];

  return clientMetrics;
}

- (gdt_client_metrics_LogEventDropped)logEventDroppedWithCounter:
    (GDTCORDroppedEventsCounter *)counter {
  gdt_client_metrics_LogEventDropped proto = gdt_client_metrics_LogEventDropped_init_zero;
  proto.events_dropped_count = counter.eventCount;
  proto.reason = [self reasonProtoWithReason:counter.dropReason];

  return proto;
}

- (gdt_client_metrics_LogEventDropped_Reason)reasonProtoWithReason:(GDTCOREventDropReason)reason {
  switch (reason) {
    case GDTCOREventDropReasonUnknown:
      return gdt_client_metrics_LogEventDropped_Reason_REASON_UNKNOWN;
    case GDTCOREventDropReasonMessageTooOld:
      return gdt_client_metrics_LogEventDropped_Reason_MESSAGE_TOO_OLD;
    case GDTCOREventDropReasonStorageFull:
      return gdt_client_metrics_LogEventDropped_Reason_CACHE_FULL;
    case GDTCOREventDropReasonMaxRetriesReached:
      return gdt_client_metrics_LogEventDropped_Reason_MAX_RETRIES_REACHED;
    case GDTCOREventDropReasonServerError:
      return gdt_client_metrics_LogEventDropped_Reason_SERVER_ERROR;
  }
}

@end
