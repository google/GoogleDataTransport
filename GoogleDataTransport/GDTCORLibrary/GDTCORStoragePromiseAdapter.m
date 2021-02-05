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

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORStoragePromiseAdapter.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORUploadBatch.h"

NS_ASSUME_NONNULL_BEGIN

@interface GDTCORStoragePromiseAdapter ()

@property(nonatomic, readonly) dispatch_queue_t storageQueue;

@end

@implementation GDTCORStoragePromiseAdapter

- (instancetype)initWithStorage:(id<GDTCORStorageProtocol>)storage {
  self = [super init];
  if (self) {
    _storage = storage;
    if ([storage respondsToSelector:@selector(storageQueue)]) {
      _storageQueue = [storage storageQueue];
    } else {
      _storageQueue = dispatch_queue_create("GDTCORStoragePromiseAdapter", DISPATCH_QUEUE_SERIAL);
    }
  }
  return self;
}

- (FBLPromise<NSSet<NSNumber *> *> *)batchIDsForTarget:(GDTCORTarget)target {
  return [FBLPromise onQueue:self.storageQueue
        wrapObjectCompletion:^(FBLPromiseObjectCompletion _Nonnull handler) {
          [self.storage batchIDsForTarget:target onComplete:handler];
        }];
}

- (FBLPromise<NSNull *> *)removeBatchWithID:(NSNumber *)batchID deleteEvents:(BOOL)deleteEvents {
  return [FBLPromise onQueue:self.storageQueue
              wrapCompletion:^(FBLPromiseCompletion _Nonnull handler) {
                [self.storage removeBatchWithID:batchID deleteEvents:deleteEvents onComplete:handler];
              }];
}

- (FBLPromise<NSNull *> *)removeBatchesWithIDs:(NSSet<NSNumber *> *)batchIDs
                                  deleteEvents:(BOOL)deleteEvents {
  NSMutableArray<FBLPromise *> *removeBatchPromises =
      [NSMutableArray arrayWithCapacity:batchIDs.count];
  for (NSNumber *batchID in batchIDs) {
    [removeBatchPromises addObject:[self removeBatchWithID:batchID deleteEvents:deleteEvents]];
  }

  return [FBLPromise onQueue:self.storageQueue all:[removeBatchPromises copy]].thenOn(
      self.storageQueue, ^id(id result) {
        return [FBLPromise resolvedWith:[NSNull null]];
      });
}

- (FBLPromise<NSNull *> *)removeAllBatchesForTarget:(GDTCORTarget)target
                                       deleteEvents:(BOOL)deleteEvents {
  return
      [self batchIDsForTarget:target].thenOn(self.storageQueue, ^id(NSSet<NSNumber *> *batchIDs) {
        return [self removeBatchesWithIDs:batchIDs deleteEvents:NO];
      });
}

- (FBLPromise<NSNumber *> *)hasEventsForTarget:(GDTCORTarget)target {
  return [FBLPromise onQueue:self.storageQueue
          wrapBoolCompletion:^(FBLPromiseBoolCompletion _Nonnull handler) {
            [self.storage hasEventsForTarget:target onComplete:handler];
          }];
}

- (FBLPromise<GDTCORUploadBatch *> *)batchWithEventSelector:
                                         (GDTCORStorageEventSelector *)eventSelector
                                            batchExpiration:(NSDate *)expiration {
  return [FBLPromise
      onQueue:self.storageQueue
        async:^(FBLPromiseFulfillBlock _Nonnull fulfill, FBLPromiseRejectBlock _Nonnull reject) {
          [self.storage batchWithEventSelector:eventSelector
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

// TODO: More comprehensive error.
- (NSError *)genericRejectedPromiseErrorWithReason:(NSString *)reason {
  return [NSError errorWithDomain:@"GDTCORFlatFileStorage"
                             code:-1
                         userInfo:@{NSLocalizedFailureReasonErrorKey : reason}];
}

#pragma mark -

- (void)storeEvent:(nonnull GDTCOREvent *)event onComplete:(void (^ _Nullable)(BOOL, NSError * _Nullable))completion {
  [self.storage storeEvent:event onComplete:completion];
}

- (void)hasEventsForTarget:(GDTCORTarget)target onComplete:(nonnull void (^)(BOOL))onComplete {
  [self.storage hasEventsForTarget:target onComplete:onComplete];
}

- (void)batchWithEventSelector:(nonnull GDTCORStorageEventSelector *)eventSelector batchExpiration:(nonnull NSDate *)expiration onComplete:(nonnull GDTCORStorageBatchBlock)onComplete {
  [self.storage batchWithEventSelector:eventSelector batchExpiration:expiration onComplete:onComplete];
}

- (void)removeBatchWithID:(nonnull NSNumber *)batchID deleteEvents:(BOOL)deleteEvents onComplete:(void (^ _Nullable)(void))onComplete {
  [self.storage removeBatchWithID:batchID deleteEvents:deleteEvents onComplete:onComplete];
}

- (void)batchIDsForTarget:(GDTCORTarget)target onComplete:(nonnull void (^)(NSSet<NSNumber *> * _Nullable))onComplete {
  [self.storage batchIDsForTarget:target onComplete:onComplete];
}

- (void)checkForExpirations {
  [self.storage checkForExpirations];
}

- (void)storeLibraryData:(nonnull NSData *)data forKey:(nonnull NSString *)key onComplete:(nullable void (^)(NSError * _Nullable))onComplete {
  [self.storage storeLibraryData:data forKey:key onComplete:onComplete];
}

- (void)libraryDataForKey:(nonnull NSString *)key onFetchComplete:(nonnull void (^)(NSData * _Nullable, NSError * _Nullable))onFetchComplete setNewValue:(NSData * _Nullable (^ _Nullable)(void))setValueBlock {
  [self.storage libraryDataForKey:key onFetchComplete:onFetchComplete setNewValue:setValueBlock];
}


- (void)removeLibraryDataForKey:(nonnull NSString *)key onComplete:(nonnull void (^)(NSError * _Nullable))onComplete {
  [self.storage removeLibraryDataForKey:key onComplete:onComplete];
}


- (void)storageSizeWithCallback:(nonnull void (^)(GDTCORStorageSizeBytes))onComplete {
  [self.storage storageSizeWithCallback:onComplete];
}

@end

NS_ASSUME_NONNULL_END
