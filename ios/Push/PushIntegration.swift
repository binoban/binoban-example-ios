import Combine
import Foundation
import UIKit
import UserNotifications

/**
 Firebase-neutral contract for the push integration.

 The `canImport(FirebaseMessaging)` branch in `PushBootstrap.swift` backs it with
 Firebase Cloud Messaging; without that package linked it resolves to a disabled
 stub. Keeping this file free of Firebase types is what lets the default project —
 which declares no Firebase dependency — compile and run as-is.
 */
protocol PushIntegration: AnyObject {
    /// `true` only when FirebaseMessaging is linked into the target.
    var isEnabled: Bool { get }

    /// Human-readable state for the Push tab (what is wired, or what is missing).
    var status: String { get }

    /// Configure Firebase, initialize the SDK's notification layer, install the
    /// interaction handler, and claim the notification/messaging delegates.
    /// Called once from `application(_:didFinishLaunchingWithOptions:)`.
    func start(application: UIApplication, notificationDelegate: UNUserNotificationCenterDelegate)

    /// Hand the raw APNs device token to Firebase — **not** to Binoban. Binoban
    /// wants the FCM registration token; see `requestExistingToken`.
    func setAPNsToken(_ deviceToken: Data)

    /// Fetch the FCM token the app already has, register/refresh it with Binoban
    /// via `BinobanNotifications.shared.onNewToken`, and hand it back.
    ///
    /// `MessagingDelegate.messaging(_:didReceiveRegistrationToken:)` only fires on
    /// token generation and rotation, so an app that was already installed when
    /// push was added would otherwise never register. `nil` when push is disabled
    /// or the token is unavailable.
    func requestExistingToken(_ completion: @escaping (String?) -> Void)
}

/// Holder for the active [PushIntegration], resolved once at first use to whichever
/// implementation `PushBootstrap.swift` compiled.
enum PushIntegrations {
    static let current: PushIntegration = makePushIntegration()
}

/**
 Observable push state rendered by the Push tab: the current FCM token and a
 bounded log of the notification interactions the SDK reported, recorded by
 `LoggingInteractionHandler`.
 */
final class PushState: ObservableObject {
    static let shared = PushState()

    private static let maxInteractions = 10

    @Published private(set) var token: String?
    @Published private(set) var tokenResolved = false
    @Published private(set) var interactions: [String] = []

    private init() {}

    func setToken(_ token: String?) {
        onMain {
            self.token = token
            self.tokenResolved = true
        }
    }

    func addInteraction(_ entry: String) {
        onMain {
            self.interactions.insert(entry, at: 0)
            if self.interactions.count > Self.maxInteractions {
                self.interactions.removeLast(self.interactions.count - Self.maxInteractions)
            }
        }
    }

    func clearInteractions() {
        onMain { self.interactions.removeAll() }
    }

    /// `@Published` mutations must happen on the main thread; the SDK and Firebase
    /// both call back on arbitrary queues.
    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }
}

/// Notification-permission helpers. Plain `UNUserNotificationCenter` — the SDK can ask
/// on its own via `askNotificationPermissionOnStart`, but this example asks on demand
/// from the Push tab instead, which is the better experience in a real app.
enum PushPermission {
    static func status(_ completion: @escaping (String) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let label: String
            switch settings.authorizationStatus {
            case .authorized: label = "authorized"
            case .denied: label = "denied"
            case .notDetermined: label = "not determined"
            case .provisional: label = "provisional"
            case .ephemeral: label = "ephemeral"
            @unknown default: label = "unknown"
            }
            DispatchQueue.main.async { completion(label) }
        }
    }

    /// Asks for permission and, when granted, registers with APNs — without
    /// `registerForRemoteNotifications()` no APNs token is issued, so Firebase never
    /// mints an FCM token and the device is unreachable.
    static func request(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    if granted { UIApplication.shared.registerForRemoteNotifications() }
                    completion(granted)
                }
            }
    }
}
