import SwiftUI
import UserNotifications
import binoban

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static private(set) var instance: AppDelegate! = nil
    var binoban: Binoban!

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Request your credentials and deployment host from support@binoban.io and
        // replace the placeholders below. For Binoban-hosted accounts apiHost is
        // "api.binoban.io"; on-prem / white-label deployments use their own host.
        binoban = BinobanFactory.shared.create(
            apiKey: "YOUR_API_KEY",
            sourceIdentifier: "YOUR_SOURCE_IDENTIFIER"
        ) { config in
            config.application = UIApplication.shared
            config.apiHost = "YOUR_API_HOST"
        }

        Binoban.companion.debugLogsEnabled = true
        print(">>>>>>>>>>>>> anonymousId:" + binoban.anonymousId())

        AppDelegate.instance = self

        // Push is opt-in and resolved at compile time: with FirebaseMessaging linked this
        // configures Firebase and wires the delegates below; without it this is a no-op
        // and the Push tab shows how to turn it on. See README § Push notifications.
        PushIntegrations.current.start(application: application, notificationDelegate: self)

        return true
    }

    func flush() { binoban.flush() }
    func reset() { binoban.reset() }
    func track(name: String, properties: [String: Any]) { binoban.track(name: name, properties: properties) }
    func identify(userId: String, traits: [String: Any]) { binoban.identify(userId: userId, traits: traits) }

    // Settings — runtime-changeable
    func setDebugLogs(_ enabled: Bool) { Binoban.companion.debugLogsEnabled = enabled }
    func getDebugLogs() -> Bool { Binoban.companion.debugLogsEnabled }
    func setSdkEnabled(_ enabled: Bool) { binoban.enabled = enabled }
    func getSdkEnabled() -> Bool { binoban.enabled }
    func setFlushAt(_ value: Int) { binoban.configuration.flushAt = Int32(value) }
    func getFlushAt() -> Int { Int(binoban.configuration.flushAt) }
    func setFlushInterval(_ value: Int) { binoban.configuration.flushInterval = Int32(value) }
    func getFlushInterval() -> Int { Int(binoban.configuration.flushInterval) }

    // Settings — read-only info
    func getApiHost() -> String { binoban.configuration.apiHost }
    func getCollectDeviceId() -> Bool { binoban.configuration.collectDeviceId }
    func getTrackLifecycleEvents() -> Bool { binoban.configuration.trackApplicationLifecycleEvents }
    func getAnonymousId() -> String { binoban.anonymousId() }

    // MARK: - Push forwarding
    //
    // The SDK never registers its own UNUserNotificationCenterDelegate — this app owns it
    // and forwards. These callbacks touch no Firebase type, so they stay in the default
    // build as a readable reference; they simply never fire until push is enabled.
    // Recipe: https://docs.binoban.io/developers/engage/mobile-push-ios

    /// Raw APNs token. It goes to Firebase, **never** to Binoban — Binoban sends through
    /// FCM, so an APNs device token cannot reach the device. Binoban gets the FCM token
    /// from `MessagingDelegate` instead.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushIntegrations.current.setAPNsToken(deviceToken)
    }

    /// Incoming data push — this is what displays a Binoban notification. Firebase
    /// flattens a data message's keys onto `userInfo`, so `source` sits at its top level.
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if userInfo["source"] as? String == "binoban" {
            BinobanNotifications.shared.onApplicationDidReceiveRemoteNotification(userInfo: userInfo)
        } else {
            // your own push handling goes here
        }
        completionHandler(.newData)
    }

    /// Foreground presentation — reports `delivered`.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        BinobanNotifications.shared.onWillPresentForwarded(userInfo: notification.request.content.userInfo)
        completionHandler([.banner, .sound])
    }

    /// User interaction — reports `clicked`, or `closed` on a swipe-away.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionId = response.actionIdentifier == UNNotificationDefaultActionIdentifier
            ? nil : response.actionIdentifier
        let dismissed = response.actionIdentifier == UNNotificationDismissActionIdentifier

        BinobanNotifications.shared.onDidReceiveForwarded(
            userInfo: response.notification.request.content.userInfo,
            actionId: actionId,
            dismissed: dismissed
        )
        completionHandler()
    }
}

@main
struct iosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
