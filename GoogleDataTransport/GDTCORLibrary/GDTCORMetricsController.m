/*
 * Copyright 2022 Google LLC
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

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsController.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORRegistrar.h"

@implementation GDTCORMetricsController

+ (void)load {
  [[GDTCORRegistrar sharedInstance] registerMetricsController:[self sharedInstance]
                                                       target:kGDTCORTargetCSH];
  [[GDTCORRegistrar sharedInstance] registerMetricsController:[self sharedInstance]
                                                       target:kGDTCORTargetFLL];
}

+ (instancetype)sharedInstance {
  static id sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    // TODO(ncooke3): Implement.
  }
  return self;
}

- (nonnull FBLPromise<NSNull *> *)confirmMetrics:(nonnull GDTCORMetrics *)metrics
                                    wereUploaded:(BOOL)uploaded {
  // TODO(ncooke3): Implement.
  return [FBLPromise resolvedWith:nil];
}

- (nonnull FBLPromise<GDTCORMetrics *> *)fetchMetrics {
  // TODO(ncooke3): Implement.
  return [FBLPromise resolvedWith:nil];
}

- (nonnull FBLPromise<NSNull *> *)logEventsDroppedForReason:(GDTCOREventDropReason)reason
                                                     events:(nonnull NSSet<GDTCOREvent *> *)events {
  // TODO(ncooke3): Implement.
  return [FBLPromise resolvedWith:nil];
}

- (BOOL)isMetricsCollectionSupportedForTarget:(GDTCORTarget)target {
  switch (target) {
    // Only the Firelog backend supports metrics collection.
    case kGDTCORTargetFLL:
    case kGDTCORTargetCSH:
    case kGDTCORTargetTest:
      return YES;

    case kGDTCORTargetCCT:
    case kGDTCORTargetINT:
      return NO;
  }

  NSAssert(NO, @"This code path shouldn't be reached.");
}

#pragma mark - GDTCORStorageDelegate

- (void)storage:(id<GDTCORStoragePromiseProtocol>)storage
    didRemoveExpiredEvent:(GDTCOREvent *)event {
  // TODO(ncooke): Implement.
}

- (void)storage:(id<GDTCORStoragePromiseProtocol>)storage didDropEvent:(GDTCOREvent *)event {
  // TODO(ncooke): Implement.
}

@end
