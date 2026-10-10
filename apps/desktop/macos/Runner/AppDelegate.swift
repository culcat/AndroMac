import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {

    private var hostApi: MacOsHostApiImpl?

    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        let controller: FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController

        // Initialize native macOS Host API bridge with Flutter binary messenger
        hostApi = MacOsHostApiImpl(binaryMessenger: controller.engine.binaryMessenger)

        // Initialize macOS system menu bar tray item
        TrayManager.shared.setup(
            onOpenWindow: { [weak self] in
                self?.mainFlutterWindow?.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            },
            onFindPhone: {
                // Handled via Flutter channel
            },
            onTogglePause: {
                // Handled via Flutter channel
            }
        )

        super.applicationDidFinishLaunching(aNotification)
    }

    override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            mainFlutterWindow?.makeKeyAndOrderFront(nil)
        }
        return true
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running in background menu bar even when main window is closed
        return false
    }
}
