# Binoban iOS SDK — Example App

A minimal SwiftUI reference app showing how to integrate the **Binoban SDK** into an
iOS project.

Binoban is enterprise CDXP infrastructure for customer data, activation, retail media,
advertising, and decisioning. This example demonstrates the client-side event and
identity APIs you use to send customer signals into a Binoban deployment.

> **Status:** Reference example · tested against Binoban iOS SDK **1.0.0**.

## What it shows

| Feature | Description |
|---|---|
| **Track** | Send a named event with custom key-value properties |
| **Identify** | Identify a user by ID with custom traits |
| **Flush** | Immediately dispatch any buffered events to the server |
| **Reset** | Clear the current user identity and reset SDK state |
| **Settings** | Toggle debug logs / SDK enabled, adjust `flushAt` & `flushInterval`, view read-only config |
| **JSON display** | See the exact payload sent for each call |

## Supported environments

- **Binoban iOS SDK:** iOS **12.0+**. You can lower this example's deployment target to
  match your app's minimum supported OS, down to iOS 12.0.
- **This example app:** builds against a deployment target of iOS **15.0**.
- **Xcode 15 or later** (Swift tools 5.9+).
- [Swift Package Manager](https://www.swift.org/package-manager/) for dependency
  management (built into Xcode — nothing extra to install).

## Installation

The SDK is distributed as a Swift package that vends a prebuilt XCFramework
([github.com/binoban/binoban-sdk-swift](https://github.com/binoban/binoban-sdk-swift)).
This example already declares the dependency, pinned to an exact version:

```
https://github.com/binoban/binoban-sdk-swift · Exact Version · 1.0.0
```

Just open the project and let Xcode resolve packages:

```sh
open ios.xcodeproj     # SPM projects open the .xcodeproj directly — there is no workspace
```

On first open, Xcode fetches the package and its XCFramework. If resolution stalls, use
**File → Packages → Resolve Package Versions**. To integrate the SDK into your own app,
add the same package via **File → Add Package Dependencies…** and point it at
`https://github.com/binoban/binoban-sdk-swift`.

## Usage

1. Request your credentials and deployment host from **support@binoban.io**:
   - **API Key** (`apiKey`)
   - **Source Identifier** (`sourceIdentifier`)
   - **API Host** (`apiHost`) — `api.binoban.io` for Binoban-hosted accounts; on-prem /
     white-label deployments use their own host.

2. In `ios/iosApp.swift`, replace the placeholders:

```swift
analytics = BinobanFactory.shared.create(
    apiKey: "YOUR_API_KEY",
    sourceIdentifier: "YOUR_SOURCE_IDENTIFIER"
) { config in
    config.application = UIApplication.shared
    config.apiHost = "YOUR_API_HOST"
}
```

3. Select a simulator or device and press **Run**.

## SDK integration pattern

```swift
import binoban

class AppDelegate: NSObject, UIApplicationDelegate {
    var analytics: Binoban!

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        analytics = BinobanFactory.shared.create(
            apiKey: "YOUR_API_KEY",
            sourceIdentifier: "YOUR_SOURCE_IDENTIFIER"
        ) { config in
            config.application = UIApplication.shared
            config.apiHost = "YOUR_API_HOST"
        }
        return true
    }
}
```

Key methods:

```swift
analytics.track(name: "purchase", properties: ["item": "shoes", "price": "49.99"])
analytics.identify(userId: "user-123", traits: ["email": "user@example.com"])
analytics.flush()
analytics.reset()
```

## Objective-C integration

The SDK framework is fully Objective-C compatible. KMP exports all public types with a
`Binoban` prefix, so `Binoban` becomes `BinobanBinoban`, `BinobanFactory` stays
`BinobanFactory`, and so on.

**AppDelegate.m**

```objc
#import <binoban/binoban.h>

@interface AppDelegate ()
@property (nonatomic, strong) BinobanBinoban *analytics;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.analytics = [BinobanFactory.shared
        createApiKey:@"YOUR_API_KEY"
        sourceIdentifier:@"YOUR_SOURCE_IDENTIFIER"
        configs:^(BinobanConfiguration *config) {
            config.application = application;
            config.apiHost = @"YOUR_API_HOST";
        }];
    BinobanBinoban.companion.debugLogsEnabled = YES;
    return YES;
}

@end
```

**Key method calls**

```objc
[self.analytics trackName:@"purchase" properties:@{ @"item": @"shoes", @"price": @"49.99" }];
[self.analytics identifyUserId:@"user-123" traits:@{ @"email": @"user@example.com" }];
[self.analytics flush];
[self.analytics reset];
```

## Push notifications

Push notification support requires an Apple Developer account with APNs entitlements.
Contact Binoban customer support for setup instructions once your provisioning is ready.

## Documentation

- Developer documentation: [docs.binoban.io](https://docs.binoban.io)
- Website: [binoban.io](https://binoban.io)

## Security

Please report security issues privately to **security@binoban.io**. See
[SECURITY.md](SECURITY.md). Do not open public issues for vulnerabilities.

## License

Released under the [MIT License](LICENSE), matching the Binoban iOS SDK.
