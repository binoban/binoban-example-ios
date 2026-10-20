<img src="https://raw.githubusercontent.com/binoban/.github/63ddb277b487b407613e98205a324d4fc6b1019c/profile/binoban-star-indigo-on-white.png" alt="Binoban indigo star" width="72" height="72">

# Binoban iOS Reference App

Explore customer event tracking, user identification, and optional push integration in a native iOS app built with SwiftUI.

[Example app guide](https://docs.binoban.io/developers/reference/example-apps) · [Swift package](https://github.com/binoban/binoban-sdk-swift) · [Push guide](https://docs.binoban.io/developers/engage/mobile-push-ios)

## What this repository provides

A reference app that consumes the Binoban iOS SDK through Swift Package Manager, pinned to `1.3.0`. Use it to inspect client calls and configuration, then apply the integration pattern to your own app.

## Requirements

| Component | Requirement |
| --- | --- |
| IDE | Xcode 15+ on macOS; Swift tools 5.9+ |
| Reference app target | iOS 15.0+ |
| SDK minimum | iOS 12.0+ |
| Dependency manager | Swift Package Manager, included with Xcode |
| Configuration | Source API key, source identifier, and deployment API host |
| Optional push | Your Firebase project, APNs configuration, and app capabilities |

The example app's iOS target is higher than the SDK's minimum. Changing that target also requires checking the app's SwiftUI API availability.

## Get started

### 1. Open the project

Clone this repository, then open the Xcode project:

```sh
open ios.xcodeproj
```

Xcode resolves the existing package dependency and downloads its XCFramework. If resolution stalls, choose **File > Packages > Resolve Package Versions**.

### 2. Configure your deployment

Request your API key, source identifier, and API host from [tech@binoban.io](mailto:tech@binoban.io). Replace the placeholders in [ios/iosApp.swift](ios/iosApp.swift):

```swift
binoban = BinobanFactory.shared.create(
    apiKey: "YOUR_API_KEY",
    sourceIdentifier: "YOUR_SOURCE_IDENTIFIER"
) { config in
    config.application = UIApplication.shared
    config.apiHost = "YOUR_API_HOST"
}
```

Use the host supplied for your deployment. On-premise and white-label deployments use their own endpoint.

### 3. Run the app

Select a simulator or device and press **Run**. Select your signing team when running on a physical device. Firebase setup is optional; the default project contains no Firebase dependency.

## Explore the example

| Feature | What you can explore |
| --- | --- |
| Track | Named events with custom properties |
| Identify | User IDs and custom traits |
| Flush | Request delivery of buffered events |
| Reset | Clear the current identity and reset SDK state |
| Settings | Debug logs, SDK enablement, flush thresholds, and configuration |
| JSON display | Inspect the inputs for each call |
| Push | Optional FCM token registration, display, and interaction reporting |

## Verify your integration

Use **Track**, then **Flush**. Check the SDK logs and confirm event acceptance using the [Developer Quick Start](https://docs.binoban.io/developers/quickstart). The JSON display shows call inputs; it is not a delivery receipt.

If no events arrive, check the source credentials and `apiHost`. For push, follow the device, delegate, and Firebase checks below. For ATT and privacy manifest guidance, see the [iOS SDK README](https://github.com/binoban/binoban-sdk-swift#privacy-manifest).

## SDK integration pattern

```swift
import UIKit
import binoban

class AppDelegate: NSObject, UIApplicationDelegate {
    var binoban: Binoban!

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        binoban = BinobanFactory.shared.create(
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
binoban.track(name: "Order Completed", properties: ["item": "shoes", "price": "49.99"])
binoban.identify(userId: "user-123", traits: ["email": "user@example.com"])
binoban.flush()
binoban.reset()
```

## Objective-C integration

The SDK framework is fully Objective-C compatible. KMP exports all public types with a
`Binoban` prefix, so `Binoban` becomes `BinobanBinoban`, `BinobanFactory` stays
`BinobanFactory`, and so on.

**AppDelegate.m**

```objc
#import <binoban/binoban.h>

@interface AppDelegate ()
@property (nonatomic, strong) BinobanBinoban *binoban;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.binoban = [BinobanFactory.shared
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
[self.binoban trackName:@"Order Completed" properties:@{ @"item": @"shoes", @"price": @"49.99" }];
[self.binoban identifyUserId:@"user-123" traits:@{ @"email": @"user@example.com" }];
[self.binoban flush];
[self.binoban reset];
```

## Push notifications

Push runs on Firebase Cloud Messaging and is **optional**. The default project declares
no Firebase dependency and carries no `GoogleService-Info.plist`, so it can run without Firebase setup. The **Push** tab shows the enable steps. Turning it on requires your own
Firebase project and an Apple Developer account with APNs configured; Binoban does not
wrap Firebase.

> The integration here mirrors the recipe in the public docs:
> [App push on iOS](https://docs.binoban.io/developers/engage/mobile-push-ios).
> That page is the source of truth: read it for the why behind each step, and
> [Set up Firebase for Binoban push](https://docs.binoban.io/developers/engage/firebase-setup)
> for the APNs key upload.

### Enable push in this example

1. **Link FirebaseMessaging.** **File → Add Package Dependencies…** →
   `https://github.com/firebase/firebase-ios-sdk`, and add the **FirebaseMessaging**
   product to the `ios` target.

   The Swift source branches on `#if canImport(FirebaseMessaging)`, so linking the
   package is the single switch that turns push on. Nothing else needs editing.

2. **Add your Firebase config.** Download `GoogleService-Info.plist` for the iOS app
   (bundle id `io.binoban.sdk.demo.ios`) from your Firebase console and add it to the
   `ios/` folder. It is gitignored: never commit it.

3. **Enable the capabilities.** In **Signing & Capabilities**, add **Push
   Notifications** and **Background Modes → Remote notifications**. Background Modes
   is required: Binoban's messages are data-only, and without it iOS will not wake the
   app to display them.

4. **Run on a physical device.** Use a physical device for end-to-end validation of this example's APNs and FCM flow.

Without the package the project still builds with zero Firebase setup. Adding the
package but not the `.plist` also builds: the Push tab then reports the missing
config rather than crashing on `FirebaseApp.configure()`.

### How the push path is wired

Firebase-touching code is confined to the `canImport` branch of
`ios/Push/PushBootstrap.swift`, so the default build never references a Firebase type.
The wiring follows the [documented steps](https://docs.binoban.io/developers/engage/mobile-push-ios):

1. **Initialize at launch**, before any push can arrive:
   ```swift
   BinobanNotifications.shared.initializeNotifications(
       configuration: NotificationPlatformConfigurationIos(
           askNotificationPermissionOnStart: false,
           notificationSoundName: nil
       )
   )
   ```
   This example passes `false` and asks for permission from the Push tab instead:
   usually the better experience. Pass `true` to have the SDK ask on start.

2. **Register the FCM token** from Firebase's `MessagingDelegate`:
   ```swift
   func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
       guard let token = fcmToken else { return }
       BinobanNotifications.shared.onNewToken(token: token)
   }
   ```
   Binoban wants the **FCM registration token**, not the raw APNs device token: the
   APNs token goes to Firebase (`Messaging.messaging().apnsToken`) and never to
   Binoban.

3. **Forward the notification callbacks.** The SDK never registers its own
   `UNUserNotificationCenterDelegate`; `AppDelegate` owns it and forwards
   `onApplicationDidReceiveRemoteNotification` (displays the notification),
   `onWillPresentForwarded` (reports `delivered`), and `onDidReceiveForwarded`
   (reports `clicked` / `closed`). Assigning
   `UNUserNotificationCenter.current().delegate` and calling
   `registerForRemoteNotifications()` are what make those callbacks fire at all.

4. **Bootstrap the token you already have.** `didReceiveRegistrationToken` only fires
   on token generation and rotation, so the Push tab fetches the existing FCM token
   once and hands it to `onNewToken`: covering devices that were already installed
   before push was added.

A `DefaultNotificationInteractionHandler` subclass (`LoggingInteractionHandler`) calls
`super` (so SDK tracking still fires) and mirrors each interaction into the Push tab's
"Recent interactions" list. **The SDK does not open URLs on iOS**: for your own app,
route `interaction.uri` and `interaction.customData` through your navigation instead of
just logging them. See
[Route the tap yourself](https://docs.binoban.io/developers/engage/mobile-push-ios#5-route-the-tap-yourself).

### Verify it worked

1. After launch, your next flushed batch carries a `bb_notification_registered` event
   with the token (tap **Re-fetch FCM token** in the Push tab to force it).
2. Send a test campaign from the Binoban panel. The notification appears,
   `bb_notification_delivered` follows, and tapping it produces
   `bb_notification_clicked`: the Push tab mirrors each interaction. Keep the app in
   the foreground for this check: on iOS `delivered` is reported from the
   foreground-presentation callback.

See [Push events](https://docs.binoban.io/developers/reference/events/push-events) for
the full event list and payload keys.

## Documentation and support

- [Integration guide](https://docs.binoban.io/developers/reference/example-apps)
- [Developer Quick Start](https://docs.binoban.io/developers/quickstart)
- [Report a bug or request a feature](https://github.com/binoban/binoban-example-ios/issues)
- [Contribution guide](CONTRIBUTING.md)
- Deployment access, credentials, and host configuration: [tech@binoban.io](mailto:tech@binoban.io).

## Security

Report vulnerabilities privately through the [security policy](SECURITY.md). Use placeholders when sharing configuration or reproduction steps.

## License

MIT. See [LICENSE](LICENSE).

## About Binoban

Binoban provides enterprise Customer Data Experience Platform (CDXP) infrastructure that connects customer data with prediction, decisioning, and activation across customer engagement, retail media, and advertising.

**Seer. Protector. Builder.** See the signal. Recognize risks and opportunities. Build what comes next.

[Binoban](https://binoban.io) · [Developer documentation](https://docs.binoban.io) · [GitHub organization](https://github.com/binoban)

**Future In Your Hands**
