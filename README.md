# Binoban iOS SDK — Example App

A minimal SwiftUI reference app showing how to integrate the **Binoban SDK** into an
iOS project.

Binoban is enterprise CDXP infrastructure for customer data, activation, retail media,
advertising, and decisioning. This example demonstrates the client-side event and
identity APIs you use to send customer signals into a Binoban deployment.

> **Status:** Reference example · tested against Binoban iOS SDK **0.1.x**.

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

- iOS 12.0+ (the SDK); this example project targets a recent iOS SDK — adjust the
  deployment target in Xcode to match your minimum supported OS.
- Xcode 15 or later. (The project was created with Xcode 26.2 beta; lower the
  deployment target if you build with a stable Xcode.)
- [CocoaPods](https://cocoapods.org) for dependency management.

## Installation

The SDK is distributed via CocoaPods ([cocoapods.org/pods/binoban](https://cocoapods.org/pods/binoban)).

```sh
pod install            # fetches the binoban pod and generates ios.xcworkspace
open ios.xcworkspace   # always open the workspace, not the .xcodeproj
```

The `Podfile` pins the SDK to a compatible range:

```ruby
pod 'binoban', '~> 0.1'
```

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
