/*
 * Copyright 2019 Google
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

#import "GoogleDataTransport/GDTCORTests/Common/Fakes/GDTCORStorageFake.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORStorageMetadata.h"

@implementation GDTCORStorageFake {
  /// Store the events in memory.
  NSMutableDictionary<NSString *, GDTCOREvent *> *_storedEvents;
  /// Store the metrics metadata in memory.
  GDTCORMetricsMetadata *_Nullable _storedMetricsMetadata;
}

@synthesize delegate = _delegate;

+ (instancetype)storageFake {
  return [[self alloc] init];
}

- (void)storeEvent:(GDTCOREvent *)event
        onComplete:(void (^_Nullable)(BOOL wasWritten, NSError *_Nullable))completion {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    self->_storedEvents = [[NSMutableDictionary alloc] init];
  });
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
                    onComplete:
                        (nonnull void (^)(NSNumber *_Nullable batchID,
                                          NSSet<GDTCOREvent *> *_Nullable events))onComplete {
}

- (void)removeBatchWithID:(nonnull NSNumber *)batchID
             deleteEvents:(BOOL)deleteEvents
               onComplete:(void (^_Nullable)(void))onComplete {
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

- (void)hasEventsForTarget:(GDTCORTarget)target onComplete:(void (^)(BOOL hasEvents))onComplete {
  if (onComplete) {
    onComplete(NO);
  }
}

- (void)storageSizeWithCallback:(void (^)(uint64_t storageSize))onComplete {
}

- (void)batchIDsForTarget:(GDTCORTarget)target
               onComplete:(nonnull void (^)(NSSet<NSNumber *> *_Nonnull))onComplete {
}

- (void)checkForExpirations {
}

- (nonnull FBLPromise<NSSet<NSNumber *> *> *)batchIDsForTarget:(GDTCORTarget)target {
  NSAssert(NO, @"This API should be implemented if this fake is used in tests.");
  return [FBLPromise resolvedWith:nil];
}

- (nonnull FBLPromise<GDTCORUploadBatch *> *)batchWithEventSelector:
                                                 (nonnull GDTCORStorageEventSelector *)eventSelector
                                                    batchExpiration:(nonnull NSDate *)expiration {
  return [FBLPromise resolvedWith:nil];
}

- (nonnull FBLPromise<NSNull *> *)fetchAndUpdateMetricsWithHandler:
    (nonnull GDTCORMetricsMetadata * (^)(GDTCORMetricsMetadata *_Nullable,
                                         NSError *_Nullable))handler {
  if (_storedMetricsMetadata != nil) {
    _storedMetricsMetadata = handler(_storedMetricsMetadata, nil);
  } else {
    NSError *emptyStorageError = [NSError errorWithDomain:@"GDTCORStorageFake" code:1 userInfo:nil];
    _storedMetricsMetadata = handler(nil, emptyStorageError);
  }

  return [FBLPromise resolvedWith:nil];
}

- (nonnull FBLPromise<GDTCORStorageMetadata *> *)fetchStorageMetadata {
  GDTCORStorageMetadata *storageMetadata =
      [GDTCORStorageMetadata metadataWithCurrentCacheSize:15 * 1000 * 1000    // 15 MB
                                             maxCacheSize:20 * 1000 * 1000];  // 20 MB
  return [FBLPromise resolvedWith:storageMetadata];
}

- (nonnull FBLPromise<NSNumber *> *)hasEventsForTarget:(GDTCORTarget)target {
  return [FBLPromise resolvedWith:nil];
}

- (nonnull FBLPromise<NSNull *> *)removeAllBatchesForTarget:(GDTCORTarget)target
                                               deleteEvents:(BOOL)deleteEvents {
  return [FBLPromise resolvedWith:nil];
}

- (nonnull FBLPromise<NSNull *> *)removeBatchWithID:(nonnull NSNumber *)batchID
                                       deleteEvents:(BOOL)deleteEvents {
  return [FBLPromise resolvedWith:nil];
}

- (nonnull FBLPromise<NSNull *> *)removeBatchesWithIDs:(nonnull NSSet<NSNumber *> *)batchIDs
                                          deleteEvents:(BOOL)deleteEvents {
  return [FBLPromise resolvedWith:nil];
}

@end
