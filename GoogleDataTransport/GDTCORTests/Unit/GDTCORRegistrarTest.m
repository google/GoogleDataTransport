/*
 * Copyright 2018 Google
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

#import "GoogleDataTransport/GDTCORTests/Unit/GDTCORTestCase.h"

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORRegistrar.h"

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORRegistrar_Private.h"
#import "GoogleDataTransport/GDTCORTests/Common/Fakes/GDTCORMetricsControllerFake.h"
#import "GoogleDataTransport/GDTCORTests/Common/Fakes/GDTCORStorageFake.h"
#import "GoogleDataTransport/GDTCORTests/Unit/Helpers/GDTCORTestUploader.h"

@interface GDTCORRegistrarTest : GDTCORTestCase

@property(nonatomic) GDTCORTarget target;

@end

@implementation GDTCORRegistrarTest

- (void)setUp {
  [super setUp];
  _target = kGDTCORTargetTest;
}

/** Tests the default initializer. */
- (void)testInit {
  XCTAssertNotNil([[GDTCORRegistrarTest alloc] init]);
}

/** Test registering an uploader. */
- (void)testRegisterUpload {
  GDTCORRegistrar *registrar = [GDTCORRegistrar sharedInstance];
  GDTCORTestUploader *uploader = [[GDTCORTestUploader alloc] init];
  XCTAssertNoThrow([registrar registerUploader:uploader target:self.target]);
  XCTAssertEqual(uploader, registrar.targetToUploader[@(_target)]);
}

/** Test registering a storage. */
- (void)testRegisterStorage {
  GDTCORRegistrar *registrar = [GDTCORRegistrar sharedInstance];
  GDTCORStorageFake *storage = [[GDTCORStorageFake alloc] init];
  XCTAssertNoThrow([registrar registerStorage:storage target:self.target]);
  XCTAssertEqual(storage, registrar.targetToStorage[@(_target)]);
}

/** Test registering a metrics controller. */
- (void)testRegisterMetricsController {
  GDTCORRegistrar *registrar = [GDTCORRegistrar sharedInstance];
  GDTCORMetricsControllerFake *metricsController = [[GDTCORMetricsControllerFake alloc] init];
  XCTAssertNoThrow([registrar registerMetricsController:metricsController target:self.target]);
  XCTAssertEqual(metricsController, registrar.targetToMetricsController[@(_target)]);
}

/** Tests that the metrics controller is set as the storage delegate when the storage object is
 * registered first. Since objects are registered at `+ load` time, the order in which the storage
 * and metrics controller objects are registered is non-deterministic.
 */
- (void)testMetricsControllerIsSetAsStorageDelegate_WhenStorageIsRegisteredFirst {
  // Given
  GDTCORRegistrar *registrar = [GDTCORRegistrar sharedInstance];
  // When
  GDTCORStorageFake *storage = [[GDTCORStorageFake alloc] init];
  XCTAssertNoThrow([registrar registerStorage:storage target:self.target]);
  GDTCORMetricsControllerFake *metricsController = [[GDTCORMetricsControllerFake alloc] init];
  XCTAssertNoThrow([registrar registerMetricsController:metricsController target:self.target]);
  // Then
  dispatch_sync(registrar.registrarQueue, ^{
                    // Drain queue.
                });
  XCTAssertEqual(storage.delegate, metricsController);
}

/** Tests that the metrics controller is set as the storage delegate when the metrics controller
 * object is registered first. Since objects are registered at `+ load` time, the order in which the
 * storage and metrics controller objects are registered is non-deterministic.
 */
- (void)testMetricsControllerIsSetAsStorageDelegate_WhenMetricsControllerIsRegisteredFirst {
  // Given
  GDTCORRegistrar *registrar = [GDTCORRegistrar sharedInstance];
  // When
  GDTCORMetricsControllerFake *metricsController = [[GDTCORMetricsControllerFake alloc] init];
  XCTAssertNoThrow([registrar registerMetricsController:metricsController target:self.target]);
  GDTCORStorageFake *storage = [[GDTCORStorageFake alloc] init];
  XCTAssertNoThrow([registrar registerStorage:storage target:self.target]);
  // Then
  dispatch_sync(registrar.registrarQueue, ^{
                    // Drain queue.
                });
  XCTAssertEqual(storage.delegate, metricsController);
}

@end
