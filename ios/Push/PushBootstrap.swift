import Foundation
import UIKit
import UserNotifications
import binoban

// Push notifications are opt-in, and the FirebaseMessaging package is the switch.
//
// Add it to this target and the `canImport` branch below compiles: Firebase is
// configured, the SDK's notification layer is initialized, and the Push tab goes
// live. Leave it out — the default checked-in project does — and the app builds and
// runs with no Firebase dependency at all, with the Push tab showing the opt-in
// steps. See README § Push notifications.
//
// The recipe implemented here is the one in the public docs:
// https://docs.binoban.io/developers/engage/mobile-push-ios

#if canImport(FirebaseMessaging)

import FirebaseCore
import FirebaseMessaging

/// Firebase-backed integration: FCM owns the token, Binoban displays the message
/// and reports the interactions.
final class FirebasePushIntegration: NSObject, PushIntegration, MessagingDelegate {

    let isEnabled = true

    private(set) var status = "not started"

    func start(application: UIApplication, notificationDelegate: UNUserNotificationCenterDelegate) {
        // FirebaseApp.configure() reads GoogleService-Info.plist from the bundle and
        // raises if it is absent, so check first — that keeps the app runnable for
        // someone who linked the package but has not added their config yet.
        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else {
            status = "FirebaseMessaging is linked, but GoogleService-Info.plist is missing from the app bundle."
            return
        }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Step 2 — initialize the SDK's notification layer before any push can arrive.
        // askNotificationPermissionOnStart: false, because this example asks from the
        // Push tab instead; pass true to have the SDK ask as soon as it initializes.
        BinobanNotifications.shared.initializeNotifications(
            configuration: NotificationPlatformConfigurationIos(
                askNotificationPermissionOnStart: false,
                notificationSoundName: nil
            )
        )

        // Step 5 — own the tap. Installed before the delegates below so an interaction
        // dispatched during a cold start from a notification tap is not missed.
        NotificationInteractionManager.shared.setHandler(handler: LoggingInteractionHandler())

        // The SDK never registers its own UNUserNotificationCenterDelegate — the app
        // owns it and forwards (step 4, in AppDelegate).
        UNUserNotificationCenter.current().delegate = notificationDelegate
        Messaging.messaging().delegate = self

        // No token is ever issued without this call, even with permission granted.
        application.registerForRemoteNotifications()

        status = "Firebase configured — delegates wired"
    }

    /// The APNs device token goes to Firebase, never to Binoban. Firebase's method
    /// swizzling normally does this for you; the explicit assignment keeps it correct
    /// if swizzling is disabled (`FirebaseAppDelegateProxyEnabled = NO`).
    func setAPNsToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // Step 3 — register the FCM token (fires on generation and on every rotation).
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        BinobanNotifications.shared.onNewToken(token: token)
        PushState.shared.setToken(token)
    }

    func requestExistingToken(_ completion: @escaping (String?) -> Void) {
        Messaging.messaging().token { token, _ in
            if let token {
                // Re-registering an unchanged token is safe and is what covers devices
                // that were already installed before push was added.
                BinobanNotifications.shared.onNewToken(token: token)
            }
            DispatchQueue.main.async { completion(token) }
        }
    }
}

func makePushIntegration() -> PushIntegration { FirebasePushIntegration() }

#else

/// Stub used by the default build. Nothing is initialized and no credential is read,
/// so the example runs with zero push setup; the Push tab explains how to turn it on.
final class DisabledPushIntegration: PushIntegration {

    let isEnabled = false

    let status = "FirebaseMessaging is not linked into this target — push is off in this build."

    func start(application: UIApplication, notificationDelegate: UNUserNotificationCenterDelegate) {}

    func setAPNsToken(_ deviceToken: Data) {}

    func requestExistingToken(_ completion: @escaping (String?) -> Void) { completion(nil) }
}

func makePushIntegration() -> PushIntegration { DisabledPushIntegration() }

#endif
