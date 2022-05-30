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

#import "GoogleDataTransport/GDTCCTLibrary/Private/GDTCORMetrics+GDTCCTSupport.h"

#import <nanopb/pb.h>
#import <nanopb/pb_decode.h>
#import <nanopb/pb_encode.h>

#import "GoogleDataTransport/GDTCCTLibrary/Private/GDTCCTNanopbHelpers.h"
#import "GoogleDataTransport/GDTCCTLibrary/Protogen/nanopb/client_metrics.nanopb.h"

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCOREventDropReason.h"
#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORStorageSizeBytes.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCOREventMetricsCounter.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORConsoleLogger.h"

@implementation GDTCORMetrics (GDTCCTSupport)

- (NSData *)transportBytes {
  // Create and populate proto.
  gdt_client_metrics_ClientMetrics clientMetricsProto =
      gdt_client_metrics_ClientMetrics_init_default;

  clientMetricsProto.window =
      GDTCCTConstructTimeWindow(self.collectionStartDate, self.collectionEndDate);

  clientMetricsProto.log_source_metrics = GDTCCTConstructLogSourceMetrics(self.droppedEventCounter);

  clientMetricsProto.global_metrics =
      GDTCCTConstructGlobalMetrics(self.currentCacheSize, self.maxCacheSize);

  clientMetricsProto.app_namespace = GDTCCTEncodeString(self.bundleID);

  // Encode proto into a data buffer.
  pb_ostream_t sizeStream = PB_OSTREAM_SIZING;

  // - Encode 1 time to determine the expected size of the buffer.
  if (!pb_encode(&sizeStream, gdt_client_metrics_ClientMetrics_fields, &clientMetricsProto)) {
    GDTCORLogError(GDTCORMCETransportBytesError, @"Error in nanopb encoding for size: %s",
                   PB_GET_ERROR(&sizeStream));
  }

  // - Encode a 2nd time to actually copy the proto's bytes into the buffer.
  size_t bufferSize = sizeStream.bytes_written;
  CFMutableDataRef dataRef = CFDataCreateMutable(CFAllocatorGetDefault(), bufferSize);
  CFDataSetLength(dataRef, bufferSize);
  pb_ostream_t ostream = pb_ostream_from_buffer((void *)CFDataGetBytePtr(dataRef), bufferSize);
  if (!pb_encode(&ostream, gdt_client_metrics_ClientMetrics_fields, &clientMetricsProto)) {
    GDTCORLogError(GDTCORMCETransportBytesError, @"Error in nanopb encoding for size: %s",
                   PB_GET_ERROR(&ostream));
  }
  CFDataSetLength(dataRef, ostream.bytes_written);

  // Release the allocated proto.
  pb_release(gdt_client_metrics_ClientMetrics_fields, &clientMetricsProto);

  return CFBridgingRelease(dataRef);
}

/// Constructs and returns a ``gdt_client_metrics_LogSourceMetrics`` from the given dropped event
/// counter.
/// @param droppedEventCounter The given dropped event counter.
gdt_client_metrics_LogSourceMetrics *GDTCCTConstructLogSourceMetrics(
    GDTCOREventMetricsCounter *droppedEventCounter) {
  // The metrics proto is a repeating field where each element represents the
  // dropped event data for a log source (mapping ID).
  NSUInteger logMetricsCount = [droppedEventCounter.droppedEventCounterByMappingID count];
  gdt_client_metrics_LogSourceMetrics *repeatedLogSourceMetrics =
      calloc(logMetricsCount, sizeof(gdt_client_metrics_LogSourceMetrics));
  repeatedLogSourceMetrics->log_event_dropped_count = (pb_size_t)logMetricsCount;

  // Each log source (mapping ID) has a corresponding dropped event counter.
  // Enumerate over the dictionary of mapping IDs and, for each mappingID,
  // create a proto representation of the number of events dropped for each
  // given reason.
  __block NSUInteger logSourceIndex = 0;
  [droppedEventCounter.droppedEventCounterByMappingID
      enumerateKeysAndObjectsUsingBlock:^(NSString *mappingID,
                                          GDTCORDroppedEventCounter *eventCounterForMappingID,
                                          BOOL *__unused _) {
        // Create the log source proto for the given mapping ID. It contains a
        // repeating field to encapuslate the number of events dropped for each
        // given drop reason.
        __block gdt_client_metrics_LogSourceMetrics logSourceMetrics =
            gdt_client_metrics_LogSourceMetrics_init_zero;
        logSourceMetrics.log_source = GDTCCTEncodeString(mappingID);
        logSourceMetrics.log_event_dropped_count = (pb_size_t)eventCounterForMappingID.count;
        logSourceMetrics.log_event_dropped =
            calloc(eventCounterForMappingID.count, sizeof(gdt_client_metrics_LogSourceMetrics));

        // Each dropped event counter counts the number of events dropped for
        // each drop reason. Enumerate over all of these counters to populate
        // the log source proto's repeating field of event drop data.
        __block NSUInteger eventCounterIndex = 0;
        [eventCounterForMappingID
            enumerateKeysAndObjectsUsingBlock:^(NSNumber *eventDropReason,
                                                NSNumber *droppedEventCount, BOOL *__unused _) {
              gdt_client_metrics_LogEventDropped droppedEvents =
                  gdt_client_metrics_LogEventDropped_init_zero;
              droppedEvents.events_dropped_count = droppedEventCount.integerValue;
              droppedEvents.reason =
                  GDTCCTConvertEventDropReasonToProtoReason(eventDropReason.integerValue);

              // Append the dropped events proto to the repeated field and
              // increment the index used for appending.
              logSourceMetrics.log_event_dropped[eventCounterIndex] = droppedEvents;
              eventCounterIndex += 1;
            }];

        // Append the metrics for the given log source (mappingID) to the
        // repeated field and increment the index used for appending.
        repeatedLogSourceMetrics[logSourceIndex] = logSourceMetrics;
        logSourceIndex += 1;
      }];

  return repeatedLogSourceMetrics;
}

/// Constructs and returns a ``gdt_client_metrics_TimeWindow`` proto from the given parameters.
/// @param collectionStartDate The start of the time window.
/// @param collectionEndDate The end of the time window.
gdt_client_metrics_TimeWindow GDTCCTConstructTimeWindow(NSDate *collectionStartDate,
                                                        NSDate *collectionEndDate) {
  gdt_client_metrics_TimeWindow timeWindow = gdt_client_metrics_TimeWindow_init_zero;
  // `- [NSDate timeIntervalSince1970]` returns a time interval in seconds so
  // multiply by 1000 to convert to milliseconds.
  timeWindow.start_ms = (int64_t)collectionStartDate.timeIntervalSince1970 * 1000;
  timeWindow.end_ms = (int64_t)collectionEndDate.timeIntervalSince1970 * 1000;
  return timeWindow;
}

/// Constructs and returns a ``gdt_client_metrics_GlobalMetrics`` proto from the given parameters.
/// @param currentCacheSize The current cache size.
/// @param maxCacheSize The max cache size.
gdt_client_metrics_GlobalMetrics GDTCCTConstructGlobalMetrics(uint64_t currentCacheSize,
                                                              uint64_t maxCacheSize) {
  gdt_client_metrics_StorageMetrics storageMetrics = gdt_client_metrics_StorageMetrics_init_zero;
  storageMetrics.current_cache_size_bytes = currentCacheSize;
  storageMetrics.max_cache_size_bytes = maxCacheSize;

  gdt_client_metrics_GlobalMetrics globalMetrics = gdt_client_metrics_GlobalMetrics_init_zero;
  globalMetrics.storage_metrics = storageMetrics;

  return globalMetrics;
}

/// Returns the corresponding ``gdt_client_metrics_LogEventDropped_Reason`` for the given
/// ``GDTCOREventDropReason``.
///
/// To represent  ``GDTCOREventDropReason`` in a proto, the reason must be mapped to a
/// ``gdt_client_metrics_LogEventDropped_Reason``.
///
/// @param reason The ``GDTCOREventDropReason`` to represent in a proto.
gdt_client_metrics_LogEventDropped_Reason GDTCCTConvertEventDropReasonToProtoReason(
    GDTCOREventDropReason reason) {
  switch (reason) {
    case GDTCOREventDropReasonUnknown:
      return gdt_client_metrics_LogEventDropped_Reason_REASON_UNKNOWN;
    case GDTCOREventDropReasonMessageTooOld:
      return gdt_client_metrics_LogEventDropped_Reason_MESSAGE_TOO_OLD;
    case GDTCOREventDropReasonStorageFull:
      return gdt_client_metrics_LogEventDropped_Reason_CACHE_FULL;
    case GDTCOREventDropReasonPayloadTooBig:
      return gdt_client_metrics_LogEventDropped_Reason_PAYLOAD_TOO_BIG;
    case GDTCOREventDropReasonMaxRetriesReached:
      return gdt_client_metrics_LogEventDropped_Reason_MAX_RETRIES_REACHED;
    case GDTCOREventDropReasonInvalidPayload:
      return gdt_client_metrics_LogEventDropped_Reason_INVALID_PAYLOD;
    case GDTCOREventDropReasonServerError:
      return gdt_client_metrics_LogEventDropped_Reason_SERVER_ERROR;
  }
}

@end
