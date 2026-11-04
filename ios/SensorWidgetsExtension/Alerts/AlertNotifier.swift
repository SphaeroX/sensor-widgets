import Foundation
import UserNotifications

/// Posts threshold notifications from the widget extension. iOS drops them silently
/// when the app was not granted notification permission (requested in AppDelegate).
public enum AlertNotifier {
    public static func post(widget: WidgetDefinition, hit: AlertHit) {
        let content = UNMutableNotificationContent()
        content.title = AlertMessage.title(widget)
        content.body = AlertMessage.body(widget, hit)
        content.sound = .default
        // One notification per widget and target: a new crossing replaces the old one.
        let request = UNNotificationRequest(identifier: "\(widget.id)|\(hit.rule.target)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
