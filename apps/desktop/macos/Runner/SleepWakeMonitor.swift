import Cocoa

/// Monitors system sleep and wake events via NSWorkspace notifications
/// allowing graceful transport session suspension and immediate reconnection on wake.
public class SleepWakeMonitor: NSObject {

    public static let shared = SleepWakeMonitor()

    private var onSleepCallback: (() -> Void)?
    private var onWakeCallback: (() -> Void)?
    private var isObserving: Bool = false

    private override init() {
        super.init()
    }

    public func startObserving(
        onSleep: @escaping () -> Void,
        onWake: @escaping () -> Void
    ) {
        guard !isObserving else { return }

        self.onSleepCallback = onSleep
        self.onWakeCallback = onWake

        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(
            self,
            selector: #selector(handleSystemSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleSystemWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        isObserving = true
    }

    public func stopObserving() {
        guard isObserving else { return }
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        isObserving = false
    }

    @objc private func handleSystemSleep(_ notification: Notification) {
        onSleepCallback?()
    }

    @objc private func handleSystemWake(_ notification: Notification) {
        onWakeCallback?()
    }

    deinit {
        stopObserving()
    }
}
