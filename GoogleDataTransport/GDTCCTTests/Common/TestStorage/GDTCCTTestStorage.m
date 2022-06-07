/*
 * Copyright 2020 Google LLC
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

#import "GoogleDataTransport/GDTCCTTests/Common/TestStorage/GDTCCTTestStorage.h"

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORUploadBatch.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

@implementation GDTCCTTestStorage {
  /** Store the events in memory. */
  NSMutableDictionary<NSString *, GDTCOREvent *> *_storedEvents;

  /** Store the batches in memory. */
  NSMutableDictionary<NSNumber *, NSSet<GDTCOREvent *> *> *_batches;
}

@synthesize delegate = _delegate;

- (instancetype)init {
  self = [super init];
  if (self) {
    _storedEvents = [[NSMutableDictionary alloc] init];
    _batches = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)storeEvent:(GDTCOREvent *)event
        onComplete:(void (^_Nullable)(BOOL wasWritten, NSError *_Nullable))completion {
  _storedEvents[event.eventID] = event;
  if (completion) {
    completion(YES, nil);
  }
}

- (void)removeEvents:(NSSet<NSString *> *)eventIDs {
  [_storedEvents removeObjectsForKeys:[eventIDs allObjects]];
}

- (void)batchWithEventSelector:(nonnull GDTCORStorageEventSelector *)eventSelector
               batchExpiration:(nonnull NSDate *)expiration
                    onComplete:(nonnull GDTCORStorageBatchBlock)onComplete {
  if (self.batchWithEventSelectorHandler) {
    self.batchWithEventSelectorHandler(eventSelector, expiration, onComplete);
  } else {
    [self defaultBatchWithEventSelector:eventSelector
                        batchExpiration:expiration
                             onComplete:onComplete];
  }
}

- (void)removeBatchWithID:(nonnull NSNumber *)batchID
             deleteEvents:(BOOL)deleteEvents
               onComplete:(void (^_Nullable)(void))onComplete {
  if (deleteEvents) {
    [_batches removeObjectForKey:batchID];
    [self.removeBatchAndDeleteEventsExpectation fulfill];
  } else {
    for (GDTCOREvent *batchedEvent in _batches[batchID]) {
      _storedEvents[batchedEvent.eventID] = batchedEvent;
    }
    [_batches removeObjectForKey:batchID];
    [self.removeBatchWithoutDeletingEventsExpectation fulfill];
  }

  if (onComplete) {
    onComplete();
  }
}

- (void)libraryDataForKey:(nonnull NSString *)key
          onFetchComplete:(nonnull void (^)(NSData *_Nullable, NSError *_Nullable))onFetchComplete
              setNewValue:(NSData *_Nullable (^_Nullable)(void))setValueBlock {
  if (onFetchComplete) {
    onFetchComplete(nil, nil);
  }
}

- (void)storeLibraryData:(NSData *)data
                  forKey:(nonnull NSString *)key
              onComplete:(nullable void (^)(NSError *_Nullable error))onComplete {
  if (onComplete) {
    onComplete(nil);
  }
}

- (void)removeLibraryDataForKey:(nonnull NSString *)key
                     onComplete:(nonnull void (^)(NSError *_Nullable))onComplete {
  if (onComplete) {
    onComplete(nil);
  }
}

- (void)hasEventsForTarget:(GDTCORTarget)target onComplete:(nonnull void (^)(BOOL))onComplete {
  if (self.hasEventsForTargetHandler) {
    self.hasEventsForTargetHandler(target, onComplete);
  } else if (onComplete) {
    onComplete(NO);
  }
}

- (void)storageSizeWithCallback:(void (^)(uint64_t storageSize))onComplete {
}

- (void)batchIDsForTarget:(GDTCORTarget)target
               onComplete:(nonnull void (^)(NSSet<NSNumber *> *_Nullable))onComplete {
  [self.batchIDsForTargetExpectation fulfill];
  if (onComplete) {
    onComplete([NSSet setWithArray:[self->_batches allKeys]]);
  }
}

- (void)checkForExpirations {
}

#pragma mark - Default Implementations

- (void)defaultBatchWithEventSelector:(nonnull GDTCORStorageEventSelector *)eventSelector
                      batchExpiration:(nonnull NSDate *)expiration
                           onComplete:(nonnull GDTCORStorageBatchBlock)onComplete {
  static NSInteger count = 0;
  NSNumber *batchID = @(count);
  count++;

  NSSet<GDTCOREvent *> *batchEvents = [NSSet setWithArray:[_storedEvents allValues]];
  _batches[batchID] = batchEvents;
  [_storedEvents removeAllObjects];

  [self.batchWithEventSelectorExpectation fulfill];
  if (onComplete) {
    onComplete(batchID, batchEvents);
  }
}

- (FBLPromise<NSSet<NSNumber *> *> *)batchIDsForTarget:(GDTCORTarget)target {
  return [FBLPromise wrapObjectCompletion:^(FBLPromiseObjectCompletion _Nonnull handler) {
    [self batchIDsForTarget:target onComplete:handler];
  }];
}

- (FBLPromise<NSNull *> *)removeBatchWithID:(NSNumber *)batchID deleteEvents:(BOOL)deleteEvents {
  return [FBLPromise wrapCompletion:^(FBLPromiseCompletion _Nonnull handler) {
    [self removeBatchWithID:batchID deleteEvents:deleteEvents onComplete:handler];
  }];
}

- (FBLPromise<NSNull *> *)removeBatchesWithIDs:(NSSet<NSNumber *> *)batchIDs
                                  deleteEvents:(BOOL)deleteEvents {
  NSMutableArray<FBLPromise *> *removeBatchPromises =
      [NSMutableArray arrayWithCapacity:batchIDs.count];
  for (NSNumber *batchID in batchIDs) {
    [removeBatchPromises addObject:[self removeBatchWithID:batchID deleteEvents:deleteEvents]];
  }

  return [FBLPromise all:[removeBatchPromises copy]].then(^id(id result) {
    return [FBLPromise resolvedWith:[NSNull null]];
  });
}

- (FBLPromise<NSNull *> *)removeAllBatchesForTarget:(GDTCORTarget)target
                                       deleteEvents:(BOOL)deleteEvents {
  return [self batchIDsForTarget:target].then(^id(NSSet<NSNumber *> *batchIDs) {
    return [self removeBatchesWithIDs:batchIDs deleteEvents:NO];
  });
}

- (FBLPromise<NSNumber *> *)hasEventsForTarget:(GDTCORTarget)target {
  return [FBLPromise wrapBoolCompletion:^(FBLPromiseBoolCompletion _Nonnull handler) {
    [self hasEventsForTarget:target onComplete:handler];
  }];
}

- (FBLPromise<GDTCORUploadBatch *> *)batchWithEventSelector:
                                         (GDTCORStorageEventSelector *)eventSelector
                                            batchExpiration:(NSDate *)expiration {
  return [FBLPromise
      async:^(FBLPromiseFulfillBlock _Nonnull fulfill, FBLPromiseRejectBlock _Nonnull reject) {
        [self batchWithEventSelector:eventSelector
                     batchExpiration:expiration
                          onComplete:^(NSNumber *_Nullable newBatchID,
                                       NSSet<GDTCOREvent *> *_Nullable batchEvents) {
                            if (newBatchID == nil || batchEvents == nil) {
                              reject([self genericRejectedPromiseErrorWithReason:
                                               @"There are no events for the selector."]);
                            } else {
                              fulfill([[GDTCORUploadBatch alloc] initWithBatchID:newBatchID
                                                                          events:batchEvents]);
                            }
                          }];
      }];
}

- (FBLPromise<NSNull *> *)fetchAndUpdateMetricsWithHandler:
    (GDTCORMetricsMetadata * (^)(GDTCORMetricsMetadata *_Nullable fetchedMetadata,
                                 NSError *_Nullable fetchError))handler {
  NSAssert(NO, @"This API should be implemented if this fake is used in tests.");
  return [FBLPromise resolvedWith:nil];
}

- (FBLPromise<GDTCORStorageMetadata *> *)fetchStorageMetadata {
  NSAssert(NO, @"This API should be implemented if this fake is used in tests.");
  return [FBLPromise resolvedWith:nil];
}

- (NSError *)genericRejectedPromiseErrorWithReason:(NSString *)reason {
  return [NSError errorWithDomain:@"GDTCORFlatFileStorage"
                             code:-1
                         userInfo:@{NSLocalizedFailureReasonErrorKey : reason}];
}

@end
