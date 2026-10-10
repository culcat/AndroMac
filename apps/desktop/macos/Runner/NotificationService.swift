import Cocoa
import UserNotifications

/// Manages native macOS user notifications via UNUserNotificationCenter.
/// Supports inline text replies via UNTextInputNotificationAction, replacement in-place, and bidirectional dismissal.
public class NotificationService: NSObject, UNUserNotificationCenterDelegate {

    public static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private var onActionCallback: ((String, String, String?) -> Void)?
    private var onDismissCallback: ((String) -> Void)?

    private let replyCategoryIdentifier = "ANDROMAC_REPLYABLE_NOTIFICATION"
    private let standardCategoryIdentifier = "ANDROMAC_STANDARD_NOTIFICATION"
    private let replyActionIdentifier = "ANDROMAC_REPLY_ACTION"

    private override init() {
        super.init()
    }

    public func setup(
        onAction: @escaping (String, String, String?) -> Void,
        onDismiss: @escaping (String) -> Void
    ) {
        self.onActionCallback = onAction
        self.onDismissCallback = onDismiss

        center.delegate = self
        requestAuthorization()
        registerCategories()
    }

    private func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                NSLog("AndroMac: Notification permission request failed: \(error.localizedDescription)")
            }
        }
    }

    private func registerCategories() {
        let replyAction = UNTextInputNotificationAction(
            identifier: replyActionIdentifier,
            title: "Ответить",
            options: [],
            textInputButtonTitle: "Отправить",
            textInputPlaceholder: "Введите сообщение..."
        )

        let replyCategory = UNNotificationCategory(
            identifier: replyCategoryIdentifier,
            actions: [replyAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let standardCategory = UNNotificationCategory(
            identifier: standardCategoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([replyCategory, standardCategory])
    }

    /// Shows or replaces an existing notification by its unique identifier.
    public func showNotification(
        identifier: String,
        title: String,
        subtitle: String?,
        body: String,
        canReply: Bool
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let sub = subtitle, !sub.isEmpty {
            content.subtitle = sub
        }
        content.body = body
        content.sound = .default
        content.categoryIdentifier = canReply ? replyCategoryIdentifier : standardCategoryIdentifier

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Deliver immediately
        )

        center.add(request) { error in
            if let error = error {
                NSLog("AndroMac: Failed to deliver notification: \(error.localizedDescription)")
            }
        }
    }

    /// Removes a delivered notification from Notification Center.
    public func removeNotification(identifier: String) {
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    // MARK: - UNUserNotificationCenterDelegate

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is active/focused
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        let actionId = response.actionIdentifier

        if actionId == UNNotificationDismissActionIdentifier {
            onDismissCallback?(identifier)
        } else if let textResponse = response as? UNTextInputNotificationResponse {
            let replyText = textResponse.userText
            onActionCallback?(identifier, actionId, replyText)
        } else {
            onActionCallback?(identifier, actionId, nil)
        }

        completionHandler()
    }
}
