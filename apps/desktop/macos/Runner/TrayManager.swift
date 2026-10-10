import Cocoa

/// Manages the macOS menu bar status item (tray icon), status badges, tooltip, and quick popup menu.
public class TrayManager: NSObject {

    public static let shared = TrayManager()

    private var statusItem: NSStatusItem?
    private var isConnected: Bool = false
    private var onOpenWindowClicked: (() -> Void)?
    private var onFindPhoneClicked: (() -> Void)?
    private var onTogglePauseClicked: (() -> Void)?

    private override init() {
        super.init()
    }

    public func setup(
        onOpenWindow: (() -> Void)? = nil,
        onFindPhone: (() -> Void)? = nil,
        onTogglePause: (() -> Void)? = nil
    ) {
        self.onOpenWindowClicked = onOpenWindow
        self.onFindPhoneClicked = onFindPhone
        self.onTogglePauseClicked = onTogglePause

        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            updateTray(
                tooltip: "AndroMac: Ожидание подключения...",
                isConnected: false,
                batteryBadge: nil
            )
        }
    }

    /// Updates tray title, tooltip, and icon depending on peer connection state.
    public func updateTray(
        title: String? = nil,
        tooltip: String,
        isConnected: Bool,
        batteryBadge: String? = nil
    ) {
        self.isConnected = isConnected

        DispatchQueue.main.async { [weak self] in
            guard let self = self, let button = self.statusItem?.button else { return }

            button.toolTip = tooltip

            // System SF Symbol for bridge connection
            let symbolName = isConnected ? "link.circle.fill" : "link.circle"
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "AndroMac")
            } else {
                button.image = NSImage(named: NSImage.networkName)
            }

            if let badge = batteryBadge, isConnected {
                button.title = " \(badge)"
            } else if let title = title {
                button.title = " \(title)"
            } else {
                button.title = ""
            }

            self.rebuildMenu(tooltip: tooltip, batteryBadge: batteryBadge)
        }
    }

    private func rebuildMenu(tooltip: String, batteryBadge: String?) {
        let menu = NSMenu()

        // Header status item
        let headerItem = NSMenuItem(title: tooltip, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        if let badge = batteryBadge, isConnected {
            let batteryItem = NSMenuItem(title: "Заряд телефона: \(badge)", action: nil, keyEquivalent: "")
            batteryItem.isEnabled = false
            menu.addItem(batteryItem)
        }

        menu.addItem(NSMenuItem.separator())

        if isConnected {
            let ringItem = NSMenuItem(title: "Найти телефон 🔔", action: #selector(handleFindPhone), keyEquivalent: "")
            ringItem.target = self
            menu.addItem(ringItem)
        }

        let openItem = NSMenuItem(title: "Открыть AndroMac", action: #selector(handleOpenWindow), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Завершить AndroMac", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func handleOpenWindow() {
        onOpenWindowClicked?()
    }

    @objc private func handleFindPhone() {
        onFindPhoneClicked?()
    }

    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}
