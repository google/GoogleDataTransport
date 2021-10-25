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

/* Automatically generated nanopb constant definitions */
/* Generated by nanopb-0.3.9.8 */

#include "GoogleDataTransport/GDTCCTLibrary/Protogen/nanopb/client_metrics.nanopb.h"

/* @@protoc_insertion_point(includes) */
#if PB_PROTO_HEADER_VERSION != 30
#error Regenerate this file with the current version of nanopb generator.
#endif



const pb_field_t gdt_client_metrics_ClientMetrics_fields[5] = {
    PB_FIELD(  1, MESSAGE , SINGULAR, STATIC  , FIRST, gdt_client_metrics_ClientMetrics, window, window, &gdt_client_metrics_TimeWindow_fields),
    PB_FIELD(  2, MESSAGE , REPEATED, POINTER , OTHER, gdt_client_metrics_ClientMetrics, log_source_metrics, window, &gdt_client_metrics_LogSourceMetrics_fields),
    PB_FIELD(  3, MESSAGE , SINGULAR, STATIC  , OTHER, gdt_client_metrics_ClientMetrics, global_metrics, log_source_metrics, &gdt_client_metrics_GlobalMetrics_fields),
    PB_FIELD(  4, BYTES   , SINGULAR, POINTER , OTHER, gdt_client_metrics_ClientMetrics, app_namespace, global_metrics, 0),
    PB_LAST_FIELD
};

const pb_field_t gdt_client_metrics_TimeWindow_fields[3] = {
    PB_FIELD(  1, INT64   , SINGULAR, STATIC  , FIRST, gdt_client_metrics_TimeWindow, start_ms, start_ms, 0),
    PB_FIELD(  2, INT64   , SINGULAR, STATIC  , OTHER, gdt_client_metrics_TimeWindow, end_ms, start_ms, 0),
    PB_LAST_FIELD
};

const pb_field_t gdt_client_metrics_GlobalMetrics_fields[2] = {
    PB_FIELD(  1, MESSAGE , SINGULAR, STATIC  , FIRST, gdt_client_metrics_GlobalMetrics, storage_metrics, storage_metrics, &gdt_client_metrics_StorageMetrics_fields),
    PB_LAST_FIELD
};

const pb_field_t gdt_client_metrics_StorageMetrics_fields[3] = {
    PB_FIELD(  1, INT64   , SINGULAR, STATIC  , FIRST, gdt_client_metrics_StorageMetrics, current_cache_size_bytes, current_cache_size_bytes, 0),
    PB_FIELD(  2, INT64   , SINGULAR, STATIC  , OTHER, gdt_client_metrics_StorageMetrics, max_cache_size_bytes, current_cache_size_bytes, 0),
    PB_LAST_FIELD
};

const pb_field_t gdt_client_metrics_LogSourceMetrics_fields[3] = {
    PB_FIELD(  1, BYTES   , SINGULAR, POINTER , FIRST, gdt_client_metrics_LogSourceMetrics, log_source, log_source, 0),
    PB_FIELD(  2, MESSAGE , REPEATED, POINTER , OTHER, gdt_client_metrics_LogSourceMetrics, log_event_dropped, log_source, &gdt_client_metrics_LogEventDropped_fields),
    PB_LAST_FIELD
};

const pb_field_t gdt_client_metrics_LogEventDropped_fields[3] = {
    PB_FIELD(  1, INT64   , SINGULAR, STATIC  , FIRST, gdt_client_metrics_LogEventDropped, events_dropped_count, events_dropped_count, 0),
    PB_FIELD(  3, UENUM   , SINGULAR, STATIC  , OTHER, gdt_client_metrics_LogEventDropped, reason, events_dropped_count, 0),
    PB_LAST_FIELD
};



/* Check that field information fits in pb_field_t */
#if !defined(PB_FIELD_32BIT)
/* If you get an error here, it means that you need to define PB_FIELD_32BIT
 * compile-time option. You can do that in pb.h or on compiler command line.
 *
 * The reason you need to do this is that some of your messages contain tag
 * numbers or field sizes that are larger than what can fit in 8 or 16 bit
 * field descriptors.
 */
PB_STATIC_ASSERT((pb_membersize(gdt_client_metrics_ClientMetrics, window) < 65536 && pb_membersize(gdt_client_metrics_ClientMetrics, global_metrics) < 65536 && pb_membersize(gdt_client_metrics_GlobalMetrics, storage_metrics) < 65536), YOU_MUST_DEFINE_PB_FIELD_32BIT_FOR_MESSAGES_gdt_client_metrics_ClientMetrics_gdt_client_metrics_TimeWindow_gdt_client_metrics_GlobalMetrics_gdt_client_metrics_StorageMetrics_gdt_client_metrics_LogSourceMetrics_gdt_client_metrics_LogEventDropped)
#endif

#if !defined(PB_FIELD_16BIT) && !defined(PB_FIELD_32BIT)
/* If you get an error here, it means that you need to define PB_FIELD_16BIT
 * compile-time option. You can do that in pb.h or on compiler command line.
 *
 * The reason you need to do this is that some of your messages contain tag
 * numbers or field sizes that are larger than what can fit in the default
 * 8 bit descriptors.
 */
PB_STATIC_ASSERT((pb_membersize(gdt_client_metrics_ClientMetrics, window) < 256 && pb_membersize(gdt_client_metrics_ClientMetrics, global_metrics) < 256 && pb_membersize(gdt_client_metrics_GlobalMetrics, storage_metrics) < 256), YOU_MUST_DEFINE_PB_FIELD_16BIT_FOR_MESSAGES_gdt_client_metrics_ClientMetrics_gdt_client_metrics_TimeWindow_gdt_client_metrics_GlobalMetrics_gdt_client_metrics_StorageMetrics_gdt_client_metrics_LogSourceMetrics_gdt_client_metrics_LogEventDropped)
#endif


/* @@protoc_insertion_point(eof) */
