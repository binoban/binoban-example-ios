import SwiftUI

enum DemoTab: String, CaseIterable {
    case track = "Track"
    case identify = "Identify"
    case settings = "Settings"
}

struct Field: Identifiable {
    var id = UUID()
    var key: String = ""
    var value: String = ""
}

struct ContentView: View {
    @State private var selectedTab: DemoTab = .track
    @State private var eventName: String = ""
    @State private var fields: [Field] = []
    @State private var lastEventJSON: String = ""

    // Settings state — synced from SDK on tab open
    @State private var debugLogs: Bool = false
    @State private var sdkEnabled: Bool = true
    @State private var flushAt: Int = 20
    @State private var flushInterval: Int = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tab row: TRACK / IDENTIFY / SETTINGS
            HStack(spacing: 0) {
                ForEach(DemoTab.allCases, id: \.self) { tab in
                    Button(tab.rawValue.uppercased()) {
                        if tab == .settings { loadSettings() }
                        else { eventName = ""; fields = [] }
                        selectedTab = tab
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selectedTab == tab ? Color.accentColor : Color.clear)
                    .foregroundColor(selectedTab == tab ? .white : .accentColor)
                    .font(.body.weight(selectedTab == tab ? .bold : .regular))
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)

            if selectedTab == .settings {
                settingsPanel
            } else {
                eventForm
            }

            Spacer()
        }
        .padding(.top)
    }

    // MARK: - Settings panel

    private var settingsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader("Runtime Controls")

                settingsToggleRow("Debug Logs", binding: Binding(
                    get: { debugLogs },
                    set: { debugLogs = $0; AppDelegate.instance.setDebugLogs($0) }
                ))

                Divider().padding(.horizontal)

                settingsToggleRow("SDK Enabled", binding: Binding(
                    get: { sdkEnabled },
                    set: { sdkEnabled = $0; AppDelegate.instance.setSdkEnabled($0) }
                ))

                Divider().padding(.horizontal)

                Stepper("Flush At: \(flushAt) events", value: Binding(
                    get: { flushAt },
                    set: { flushAt = $0; AppDelegate.instance.setFlushAt($0) }
                ), in: 1...200)
                .padding(.horizontal)
                .padding(.vertical, 10)

                Divider().padding(.horizontal)

                Stepper("Flush Interval: \(flushInterval)s", value: Binding(
                    get: { flushInterval },
                    set: { flushInterval = $0; AppDelegate.instance.setFlushInterval($0) }
                ), in: 5...600)
                .padding(.horizontal)
                .padding(.vertical, 10)

                sectionHeader("Read-only Info")

                infoRow("API Host", AppDelegate.instance.getApiHost())
                infoRow("Collect Device ID", AppDelegate.instance.getCollectDeviceId() ? "true" : "false")
                infoRow("Track Lifecycle Events", AppDelegate.instance.getTrackLifecycleEvents() ? "true" : "false")
                infoRow("Anonymous ID", AppDelegate.instance.getAnonymousId())
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }

    private func settingsToggleRow(_ label: String, binding: Binding<Bool>) -> some View {
        Toggle(label, isOn: binding)
            .padding(.horizontal)
            .padding(.vertical, 10)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .overlay(Divider().padding(.horizontal), alignment: .bottom)
    }

    // MARK: - Event form

    private var eventForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Action row: FLUSH / RESET
            HStack(spacing: 12) {
                Button("FLUSH") { AppDelegate.instance.flush() }
                    .buttonStyle(.bordered)
                Button("RESET") { AppDelegate.instance.reset() }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            // Event name / user ID field
            TextField(
                selectedTab == .track ? "Event Name" : "User ID",
                text: $eventName
            )
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)

            // Dynamic key-value fields
            ForEach($fields) { $field in
                HStack(spacing: 8) {
                    TextField("Key", text: $field.key)
                        .textFieldStyle(.roundedBorder)
                    TextField("Value", text: $field.value)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        fields.removeAll { $0.id == field.id }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
            }

            Button("Add Field") { fields.append(Field()) }
                .padding(.horizontal)

            Button("Send \(selectedTab.rawValue)") { sendEvent() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

            // JSON payload display
            ScrollView {
                Text(lastEventJSON.isEmpty ? "Payload will appear here after sending…" : lastEventJSON)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(lastEventJSON.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
            .frame(minHeight: 140)
        }
    }

    // MARK: - Actions

    private func loadSettings() {
        debugLogs = AppDelegate.instance.getDebugLogs()
        sdkEnabled = AppDelegate.instance.getSdkEnabled()
        flushAt = AppDelegate.instance.getFlushAt()
        flushInterval = AppDelegate.instance.getFlushInterval()
    }

    private func sendEvent() {
        var props = [String: Any]()
        for field in fields where !field.key.isEmpty {
            props[field.key] = field.value
        }
        var payload = [String: Any]()
        switch selectedTab {
        case .track:
            AppDelegate.instance.track(name: eventName, properties: props)
            payload = ["type": "track", "event": eventName, "properties": props]
        case .identify:
            AppDelegate.instance.identify(userId: eventName, traits: props)
            payload = ["type": "identify", "userId": eventName, "traits": props]
        case .settings:
            return
        }
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            lastEventJSON = str
        }
    }
}

#Preview {
    ContentView()
}
