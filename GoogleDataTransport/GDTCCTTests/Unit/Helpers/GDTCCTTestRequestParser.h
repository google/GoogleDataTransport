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

#import <Foundation/Foundation.h>

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"

#import "GoogleDataTransport/GDTCCTLibrary/Protogen/nanopb/cct.nanopb.h"

NS_ASSUME_NONNULL_BEGIN

@interface GDTCCTTestRequestParser : NSObject

/// Tries to parse batched request proto from the provided request data.
/// @param data The request data.
/// @param outError An error pointer to assign parsing error if there is.
/// @return An instance of `gdt_cct_BatchedLogRequest`. This instance will contain events if parsed
/// successfully. The instance will contain no events if an error happened (check `outError`).
+ (gdt_cct_BatchedLogRequest)requestWithData:(NSData *)data error:(NSError **)outError;

/// Tries to recover `GDTCOREvent`s from the batch request proto.
/// @param batchRequest A batch request to parse.
/// @param outError An error pointer to assign parsing error if there is.
/// @return An array of `GDTCOREvent` objects from the request if parsed successfully.
+ (NSArray<GDTCOREvent *> *)eventsWithBatchRequest:(gdt_cct_BatchedLogRequest)batchRequest
                                             error:(NSError **)outError;

@end

NS_ASSUME_NONNULL_END
