import Foundation
import binoban

/**
 Mirrors every notification interaction the SDK reports into the Push tab.

 This is step 5 of the iOS push recipe —
 [Route the tap yourself](https://docs.binoban.io/developers/engage/mobile-push-ios).
 **The SDK does not open URLs on iOS**: iOS hands every tap to your delegate and
 routing belongs to your navigation, so a real app reads `interaction.uri` and
 `interaction.customData` here and routes them. This example only displays them.

 Subclassing `DefaultNotificationInteractionHandler` and calling `super` keeps the
 SDK's own tracking intact — drop the `super` call and delivery/click reporting
 stops.
 */
final class LoggingInteractionHandler: DefaultNotificationInteractionHandler {

    override func onNotificationInteraction(interaction: NotificationInteraction) {
        super.onNotificationInteraction(interaction: interaction)   // keep SDK tracking

        // A real app routes instead of logging:
        //   if let uri = interaction.uri, let url = URL(string: uri) { UIApplication.shared.open(url) }

        var lines = ["\(interaction.type.name) · \(interaction.notificationUuid)"]
        if let actionId = interaction.actionId {
            lines.append("button: \(actionId)")
        }
        if let uri = interaction.uri {
            lines.append("uri: \(uri)")
        }
        if let customData = interaction.customData, !customData.isEmpty {
            let pairs = customData.keys.sorted().map { "\($0)=\(customData[$0] ?? "")" }
            lines.append("customData: \(pairs.joined(separator: ", "))")
        }
        if let reason = interaction.reason {
            lines.append("reason: \(reason)")
        }

        PushState.shared.addInteraction(lines.joined(separator: "\n"))
    }
}
