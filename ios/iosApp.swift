import SwiftUI
import binoban

class AppDelegate: NSObject, UIApplicationDelegate {
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
