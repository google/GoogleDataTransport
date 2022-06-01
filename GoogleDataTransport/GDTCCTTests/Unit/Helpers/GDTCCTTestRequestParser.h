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

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"

#import "GoogleDataTransport/GDTCCTLibrary/Protogen/nanopb/cct.nanopb.h"
#include "GoogleDataTransport/GDTCCTLibrary/Protogen/nanopb/client_metrics.nanopb.h"

NS_ASSUME_NONNULL_BEGIN

/// A test utility class for parsing data or protos to their corresponding type.
@interface GDTCCTTestRequestParser : NSObject

/// Parses the batched log request proto from the provided data.
/// @param data The given data to parse.
/// @param outError If the return value is `nil`, an ``NSError`` indicating why the parsing
/// operation failed.
/// @return An instance of ``gdt_cct_BatchedLogRequest``.
+ (gdt_cct_BatchedLogRequest)requestWithData:(NSData *)data error:(NSError **)outError;

/// Parses the client metrics proto from the provided data.
/// @param data The given data to parse.
/// @param outError If the return value is `nil`, an ``NSError`` indicating why the parsing
/// operation failed.
/// @return An instance of ``gdt_client_metrics_ClientMetrics``. The instance will have default
/// values in the case of an error (check `outError`).
+ (gdt_client_metrics_ClientMetrics)metricsProtoWithData:(NSData *)data error:(NSError **)outError;

/// Parses the ``GDTCOREvent``s used in the given batch log request proto.
/// @param batchRequest The given proto to parse.
/// @return An array of ``GDTCOREvent`` objects from the request.
+ (NSArray<GDTCOREvent *> *)eventsWithBatchRequest:(gdt_cct_BatchedLogRequest)batchRequest;

@end

NS_ASSUME_NONNULL_END
