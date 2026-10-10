import Cocoa
import FlutterMacOS

/// Implementation of platform channel communications between macOS AppKit and Flutter.
/// Conforms to Pigeon specification defined in pigeons/macos_native.dart.
public class MacOsHostApiImpl: NSObject {

    public static let channelName = "com.andromac.bridge/macos_platform"
    private let channel: FlutterMethodChannel

    public init(binaryMessenger: FlutterBinaryMessenger) {
        self.channel = FlutterMethodChannel(name: MacOsHostApiImpl.channelName, binaryMessenger: binaryMessenger)
        super.init()

        setupMethodCallHandler()
        setupNativeEventCallbacks()
    }

    private func setupMethodCallHandler() {
        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else { return }

            switch call.method {
            case "showNotification":
                guard let args = call.arguments as? [String: Any],
                      let identifier = args["identifier"] as? String,
                      let title = args["title"] as? String,
                      let body = args["body"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing required notification fields", details: nil))
                    return
                }
                let subtitle = args["subtitle"] as? String
                let canReply = args["canReply"] as? Bool ?? false

                NotificationService.shared.showNotification(
                    identifier: identifier,
                    title: title,
                    subtitle: subtitle,
                    body: body,
                    canReply: canReply
                )
                result(nil)

            case "removeNotification":
                guard let args = call.arguments as? [String: Any],
                      let identifier = args["identifier"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing identifier", details: nil))
                    return
                }
                NotificationService.shared.removeNotification(identifier: identifier)
                result(nil)

            case "updateTray":
                guard let args = call.arguments as? [String: Any],
                      let tooltip = args["tooltip"] as? String,
                      let isConnected = args["isConnected"] as? Bool else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing required tray fields", details: nil))
                    return
                }
                let title = args["title"] as? String
                let batteryBadge = args["batteryBadge"] as? String

                TrayManager.shared.updateTray(
                    title: title,
                    tooltip: tooltip,
                    isConnected: isConnected,
                    batteryBadge: batteryBadge
                )
                result(nil)

            case "copyToPasteboard":
                guard let args = call.arguments as? [String: Any],
                      let text = args["text"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing text", details: nil))
                    return
                }
                PasteboardMonitor.shared.copyToPasteboard(text: text)
                result(nil)

            case "getPasteboardChangeCount":
                let count = PasteboardMonitor.shared.getChangeCount()
                result(count)

            case "readPasteboard":
                let text = PasteboardMonitor.shared.readCurrentText()
                result(text)

            case "registerSleepWakeObserver":
                // Observers are configured during setupNativeEventCallbacks
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func setupNativeEventCallbacks() {
        // Notification action callbacks
        NotificationService.shared.setup(
            onAction: { [weak self] identifier, actionId, replyText in
                self?.channel.invokeMethod("onNotificationAction", [
                    "identifier": identifier,
                    "actionId": actionId,
                    "replyText": replyText as Any
                ])
            },
            onDismiss: { [weak self] identifier in
                self?.channel.invokeMethod("onNotificationDismissed", [
                    "identifier": identifier
                ])
            }
        )

        // System sleep and wake callbacks
        SleepWakeMonitor.shared.startObserving(
            onSleep: { [weak self] in
                self?.channel.invokeMethod("onSystemSleep", nil)
            },
            onWake: { [weak self] in
                self?.channel.invokeMethod("onSystemWake", nil)
            }
        )

        // Pasteboard change monitoring
        PasteboardMonitor.shared.startMonitoring { [weak self] text in
            self?.channel.invokeMethod("onPasteboardChanged", [
                "text": text
            ])
        }
    }
}
