// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright 2021 Google LLC
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

import PackageDescription

let package = Package(
  name: "GoogleDataTransport",
  platforms: [.iOS(.v12), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v7)],
  products: [
    .library(
      name: "GoogleDataTransport",
      targets: ["GoogleDataTransport"]
    ),
  ],
  dependencies: [
    .package(
      url: "https://github.com/firebase/nanopb.git",
      "2.30910.0" ..< "2.30911.0"
    ),
    .package(
      url: "https://github.com/google/promises.git",
      "2.4.0" ..< "3.0.0"
    ),
  ],
  // TODO: Restructure directory structure to simplify the excludes here.
  targets: [
    .target(
      name: "GoogleDataTransport",
      dependencies: [
        .product(name: "nanopb", package: "nanopb"),
        .product(name: "FBLPromises", package: "Promises"),
      ],
      path: "GoogleDataTransport",
      exclude: [
        "generate_project.sh",
        "GDTCCTWatchOSTestApp/",
        "GDTWatchOSTestApp/",
        "GDTCCTTestApp/",
        "GDTTestApp/",
        "GDTCCTTests/",
        "GDTCORTests/",
        "ProtoSupport/",
      ],
      sources: [
        "GDTCORLibrary",
        "GDTCCTLibrary",
      ],
      resources: [.process("Resources/PrivacyInfo.xcprivacy")],
      publicHeadersPath: "GDTCORLibrary/Public",
      cSettings: [
        .headerSearchPath("../"),
        .define("GDTCOR_VERSION", to: "0.0.1"),
        .define("PB_FIELD_32BIT", to: "1"),
        .define("PB_NO_PACKED_STRUCTS", to: "1"),
        .define("PB_ENABLE_MALLOC", to: "1"),
      ],
      linkerSettings: [
        .linkedFramework(
          "SystemConfiguration",
          .when(platforms: [.iOS, .macOS, .tvOS, .macCatalyst])
        ),
        .linkedFramework("CoreTelephony", .when(platforms: [.macOS, .iOS, .macCatalyst])),
      ]
    ),
    .testTarget(
      name: "swift-test",
      dependencies: [
        "GoogleDataTransport",
      ],
      path: "SwiftPMTests/swift-test"
    ),
    .testTarget(
      name: "objc-import-test",
      dependencies: [
        "GoogleDataTransport",
      ],
      path: "SwiftPMTests/objc-import-test"
    ),
    // TODO: - need to port Network/third_party/GTMHTTPServer.m to ARC.
    // TODO: - Setup unit tests in SPM.
  ],
  cLanguageStandard: .c99,
  cxxLanguageStandard: CXXLanguageStandard.gnucxx14
)
