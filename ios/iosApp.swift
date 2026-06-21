import SwiftUI
import binoban

class AppDelegate: NSObject, UIApplicationDelegate {
    static private(set) var instance: AppDelegate! = nil
    var analytics: Binoban!

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Request your credentials and deployment host from support@binoban.io and
        // replace the placeholders below. For Binoban-hosted accounts apiHost is
        // "api.binoban.io"; on-prem / white-label deployments use their own host.
        analytics = BinobanFactory.shared.create(
            apiKey: "YOUR_API_KEY",
            sourceIdentifier: "YOUR_SOURCE_IDENTIFIER"
        ) { config in
            config.application = UIApplication.shared
            config.apiHost = "YOUR_API_HOST"
        }

        Binoban.companion.debugLogsEnabled = true
        print(">>>>>>>>>>>>> anonymousId:" + analytics.anonymousId())

        AppDelegate.instance = self
        return true
    }

    func flush() { analytics.flush() }
    func reset() { analytics.reset() }
    func track(name: String, properties: [String: Any]) { analytics.track(name: name, properties: properties) }
    func identify(userId: String, traits: [String: Any]) { analytics.identify(userId: userId, traits: traits) }

    // Settings — runtime-changeable
    func setDebugLogs(_ enabled: Bool) { Binoban.companion.debugLogsEnabled = enabled }
    func getDebugLogs() -> Bool { Binoban.companion.debugLogsEnabled }
    func setSdkEnabled(_ enabled: Bool) { analytics.enabled = enabled }
    func getSdkEnabled() -> Bool { analytics.enabled }
    func setFlushAt(_ value: Int) { analytics.configuration.flushAt = Int32(value) }
    func getFlushAt() -> Int { Int(analytics.configuration.flushAt) }
    func setFlushInterval(_ value: Int) { analytics.configuration.flushInterval = Int32(value) }
    func getFlushInterval() -> Int { Int(analytics.configuration.flushInterval) }

    // Settings — read-only info
    func getApiHost() -> String { analytics.configuration.apiHost }
    func getCollectDeviceId() -> Bool { analytics.configuration.collectDeviceId }
    func getTrackLifecycleEvents() -> Bool { analytics.configuration.trackApplicationLifecycleEvents }
    func getAnonymousId() -> String { analytics.anonymousId() }
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
