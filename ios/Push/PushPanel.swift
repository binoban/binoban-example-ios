import SwiftUI

/**
 Push tab. Two modes:
  - FirebaseMessaging not linked (the default project): shows the opt-in steps, so a
    developer reading the example knows exactly how to turn push on. No Firebase
    setup is needed to reach this screen.
  - FirebaseMessaging linked: live status — FCM token, notification permission, and
    the interactions recorded by `LoggingInteractionHandler`.
 */
struct PushPanel: View {
    var body: some View {
        if PushIntegrations.current.isEnabled {
            PushEnabledPanel()
        } else {
            PushDisabledPanel()
        }
    }
}

// MARK: - Disabled

private struct PushDisabledPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            InfoCard(
                title: "Push notifications are off in this build",
                message: "This project declares no Firebase dependency and carries no "
                    + "GoogleService-Info.plist, so it builds and runs as-is. To see the live "
                    + "push integration, enable it in four steps:"
            )
            Spacer().frame(height: 12)

            NumberedStep(1, "Add the FirebaseMessaging package: File → Add Package "
                + "Dependencies… → https://github.com/firebase/firebase-ios-sdk, and pick the "
                + "FirebaseMessaging product.")
            NumberedStep(2, "Drop your GoogleService-Info.plist into ios/. "
                + "(Never commit it — it's gitignored.)")
            NumberedStep(3, "Enable the Push Notifications capability and Background Modes → "
                + "Remote notifications. Background Modes is required: Binoban's messages are "
                + "data-only, so without it iOS never wakes the app to display them.")
            NumberedStep(4, "Run on a physical device. Push needs an APNs token, which the "
                + "simulator does not provide.")

            Spacer().frame(height: 12)
            InfoCard(
                title: "What linking Firebase wires",
                message: "BinobanNotifications.shared.initializeNotifications at launch, the FCM "
                    + "token handed to onNewToken, the existing-token bootstrap, the app's "
                    + "UNUserNotificationCenterDelegate forwarding delivery and taps to the SDK, "
                    + "and a DefaultNotificationInteractionHandler subclass that surfaces "
                    + "interactions here. Mirrors the recipe at "
                    + "docs.binoban.io/developers/engage/mobile-push-ios."
            )
            Spacer().frame(height: 16)
        }
    }
}

// MARK: - Enabled

private struct PushEnabledPanel: View {
    @ObservedObject private var state = PushState.shared
    @State private var permission = "checking…"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader("Push status")
            InfoRow("Integration", PushIntegrations.current.status)
            InfoRow("Notification permission", permission)
            InfoRow("FCM token", tokenLabel)

            Spacer().frame(height: 12)
            Button("Request notification permission") {
                PushPermission.request { _ in refreshPermission() }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)

            Spacer().frame(height: 8)
            Button("Re-fetch FCM token") {
                PushIntegrations.current.requestExistingToken { PushState.shared.setToken($0) }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)

            SectionHeader("Recent interactions")
            InfoCard(
                title: "How to test",
                message: "Send a test campaign from the Binoban panel. A notification appears; "
                    + "bb_notification_delivered follows; tapping it produces "
                    + "bb_notification_clicked. Keep the app in the foreground — on iOS "
                    + "delivered is reported from the foreground-presentation callback. Each "
                    + "interaction is mirrored here by LoggingInteractionHandler, which calls "
                    + "super so SDK tracking still fires."
            )
            Spacer().frame(height: 8)

            if state.interactions.isEmpty {
                Text("No interactions yet — send a test push and tap it.")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
            } else {
                HStack {
                    Spacer()
                    Button("Clear") { state.clearInteractions() }
                        .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                ForEach(Array(state.interactions.enumerated()), id: \.offset) { _, entry in
                    Text(entry)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
            }
            Spacer().frame(height: 16)
        }
        .onAppear {
            refreshPermission()
            // onNewToken only fires on generation/rotation, so fetch the token the app
            // already has — this is what registers an already-installed device.
            if !state.tokenResolved {
                PushIntegrations.current.requestExistingToken { PushState.shared.setToken($0) }
            }
        }
    }

    private var tokenLabel: String {
        if let token = state.token { return token }
        return state.tokenResolved ? "unavailable — see the Integration row above" : "fetching…"
    }

    private func refreshPermission() {
        PushPermission.status { permission = $0 }
    }
}

// MARK: - Local building blocks

private struct InfoCard: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
            Text(message)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

private struct NumberedStep: View {
    private let number: Int
    private let text: String

    init(_ number: Int, _ text: String) {
        self.number = number
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number).")
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
            Text(text)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
