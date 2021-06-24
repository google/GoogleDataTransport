[![Version](https://img.shields.io/cocoapods/v/GoogleDataTransport.svg?style=flat)](https://cocoapods.org/pods/GoogleDataTransport)
[![License](https://img.shields.io/cocoapods/l/GoogleDataTransport.svg?style=flat)](https://cocoapods.org/pods/GoogleDataTransport)
[![Platform](https://img.shields.io/cocoapods/p/GoogleDataTransport.svg?style=flat)](https://cocoapods.org/pods/GoogleDataTransport)

[![Actions Status][gh-datatransport-badge]][gh-actions]

# GoogleDataTransport

This library is for internal Google use only. It allows the logging of data and
telemetry from Google SDKs.

## Integration Testing
These instructions apply to minor and patch version updates. Major versions need
a customized adaptation.

After the CI is green:
* Determine the next version for release by checking the
  [tagged releases](https://github.com/google/GoogleDataTransport/tags).
  Ensure that the next release version keeps the Swift PM and CocoaPods versions in sync.
* Verify that the releasing version is the latest entry in the [CHANGELOG.md](CHANGELOG.md),
  updating it if necessary.
* Update the version in the podspec to match the latest entry in the [CHANGELOG.md](CHANGELOG.md)
* Checkout the `main` branch and ensure it is up to date.
  ```console
  git checkout main
  git pull
  ```
* Add the CocoaPods tag (`{version}` will be the latest version in the [podspec](GoogleDataTransport.podspec#L3))
  ```console
  git tag CocoaPods-{version}
  git push origin CocoaPods-{version}
  ```
* Push the podspec to the designated repo
  * If this version of GDT is intended to launch **before or with** the next Firebase release:
    <details>
    <summary>Push to <b>SpecsStaging</b></summary>

    ```console
    pod repo push --skip-tests staging GoogleDataTransport.podspec
    ```

    If the command fails with `Unable to find the 'staging' repo.`, add the staging repo with:
    ```console
    pod repo add staging git@github.com:firebase/SpecsStaging.git
    ```
    </details>
  * Otherwise:
    <details>
    <summary>Push to <b>SpecsDev</b></summary>

    ```console
    pod repo push --skip-tests dev GoogleDataTransport.podspec
    ```

    If the command fails with `Unable to find the 'dev' repo.`, add the dev repo with:
    ```console
    pod repo add dev git@github.com:firebase/SpecsDev.git
    ```
    </details>
* Run Firebase CI by waiting until next nightly or adding a PR that touches `Gemfile`.
* On google3, create a workspace and new CL. Then copybara and run a global TAP.
  <pre>
  /google/data/ro/teams/copybara/copybara third_party/firebase/ios/Releases/GoogleDataTransport/copy.bara.sky \
  --piper-description-behavior=OVERWRITE \
  --destination-cl=<b>YOUR_CL</b> gdt
  </pre>

## Publishing
The release process is as follows:
1. [Tag and release for Swift PM](#swift-package-manager)
2. [Publish to CocoaPods](#cocoapods)
3. [Create GitHub Release](#create-github-release)
4. [Perform post release cleanup](#post-release-cleanup)

### Swift Package Manager
  By creating and [pushing a tag](https://github.com/google/GoogleDataTransport/tags)
  for Swift PM, the newly tagged version will be immediately released for public use.
  Given this, please verify the intended time of release for Swift PM.
  * Add a version tag for Swift PM
  ```console
  git tag {version}
  git push origin {version}
  ```
  *Note: Ensure that any inflight PRs that depend on the new `GoogleDataTransport` version are updated to point to the
  newly tagged version rather than a checksum.*
  
### CocoaPods
* Publish the newly versioned pod to CocoaPods

  It's recommended to point to the `GoogleDataTransport.podspec` in `staging` to make sure the correct spec is being published.
  ```console
  pod trunk push ~/.cocoapods/repos/staging/GoogleDataTransport.podspec --skip-tests
  ```

  The pod push was successful if the above command logs: `🚀  GoogleDataTransport ({version}) successfully published`.
  In addition, a new commit that publishes the new version (co-authored by [CocoaPodsAtGoogle](https://github.com/CocoaPodsAtGoogle))
  should appear in the [CocoaPods specs repo](https://github.com/CocoaPods/Specs). Last, the latest version should be displayed
  on [GoogleDataTransport's CocoaPods page](https://cocoapods.org/pods/GoogleDataTransport).

### [Create GitHub Release](https://github.com/google/GoogleDataTransport/releases/new/)
  Update the [release template](https://github.com/google/GoogleDataTransport/releases/new/)'s **Tag version** and **Release title**
  fields with the latest version. In addition, reference the [Release Notes](./CHANGELOG.md) in the release's description.
  
  See [this release](https://github.com/google/GoogleDataTransport/releases/edit/9.0.1) for an example.
  
  *Don't forget to perform the [post release cleanup](#post-release-cleanup)!*

### Post Release Cleanup
  <details>
  <summary>Clean up <b>SpecsStaging</b></summary> 

  ```console
  pwd=$(pwd)
  mkdir -p /tmp/release-cleanup && cd $_
  git clone git@github.com:firebase/SpecsStaging.git
  cd SpecsStaging/
  git rm -rf GoogleDataTransport/
  git commit -m "Post publish cleanup"
  git push origin master
  rm -rf /tmp/release-cleanup 
  cd $pwd
  ```  
  </details>

## Set logging level

### Swift

- Import `GoogleDataTransport` module:
    ```swift
    import GoogleDataTransport
    ```
- Set logging level global variable to the desired value before calling `FirebaseApp.configure()`:
    ```swift
    GDTCORConsoleLoggerLoggingLevel = GDTCORLoggingLevel.debug.rawValue
    ```
### Objective-C

- Import `GoogleDataTransport`:
    ```objective-c
    #import <GoogleDataTransport/GoogleDataTransport.h>
    ```
- Set logging level global variable to the desired value before calling `-[FIRApp configure]`:
    ```objective-c
    GDTCORConsoleLoggerLoggingLevel = GDTCORLoggingLevelDebug;
    ```

## Prereqs

- `gem install --user cocoapods cocoapods-generate`
- `brew install protobuf nanopb-generator`
- `easy_install --user protobuf`

## To develop

- Run `./GoogleDataTransport/generate_project.sh` after installing the prereqs

## When adding new logging endpoint

- Use commands similar to:
    - `python -c "line='https://www.firebase.com'; print line[0::2]" `
    - `python -c "line='https://www.firebase.com'; print line[1::2]" `

## When adding internal code that shouldn't be easily usable on github

- Consider using go/copybara-library/scrubbing#cc_scrub

## Development

Ensure that you have at least the following software:

  * Xcode 12.0 (or later)
  * CocoaPods 1.10.0 (or later)
  * [CocoaPods generate](https://github.com/square/cocoapods-generate)

For the pod that you want to develop:

`pod gen GoogleDataTransport.podspec --local-sources=./ --auto-open --platforms=ios`

Note: If the CocoaPods cache is out of date, you may need to run
`pod repo update` before the `pod gen` command.

Note: Set the `--platforms` option to `macos` or `tvos` to develop/test for
those platforms. Since 10.2, Xcode does not properly handle multi-platform
CocoaPods workspaces.

### Development for Catalyst
* `pod gen GoogleDataTransport.podspec --local-sources=./ --auto-open --platforms=ios`
* Check the Mac box in the App-iOS Build Settings
* Sign the App in the Settings Signing & Capabilities tab
* Click Pods in the Project Manager
* Add Signing to the iOS host app and unit test targets
* Select the Unit-unit scheme
* Run it to build and test

Alternatively disable signing in each target:
* Go to Build Settings tab
* Click `+`
* Select `Add User-Defined Setting`
* Add `CODE_SIGNING_REQUIRED` setting with a value of `NO`

### Code Formatting

To ensure that the code is formatted consistently, run the script
[./scripts/check.sh](https://github.com/firebase/firebase-ios-sdk/blob/master/scripts/check.sh)
before creating a PR.

GitHub Actions will verify that any code changes are done in a style compliant
way. Install `clang-format` and `mint`:

```console
brew install clang-format@12
brew install mint
```

### Running Unit Tests

Select a scheme and press Command-u to build a component and run its unit tests.

## Contributing

See [Contributing](CONTRIBUTING.md) for more information on contributing to the Firebase
iOS SDK.

## License

The contents of this repository is licensed under the
[Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

[gh-actions]: https://github.com/firebase/firebase-ios-sdk/actions
[gh-datatransport-badge]: https://github.com/firebase/firebase-ios-sdk/workflows/datatransport/badge.svg
