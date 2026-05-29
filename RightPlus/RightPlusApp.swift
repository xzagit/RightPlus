import SwiftUI
import ServiceManagement

@main
struct RightPlusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("RightPlus", id: "main") {
            ContentView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 700, height: 500)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()

        if SettingsManager.shared.bool(for: .silentLaunch) {
            DispatchQueue.main.async {
                self.closeAllAppWindows()
                NSApplication.shared.setActivationPolicy(.accessory)
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindow()
        }
        return true
    }

    @objc private func windowDidClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window.canBecomeMain else { return }

        guard SettingsManager.shared.bool(for: .hideDockOnClose) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let hasVisibleMain = NSApplication.shared.windows.contains {
                $0.isVisible && $0.canBecomeMain
            }
            if !hasVisibleMain {
                NSApplication.shared.setActivationPolicy(.accessory)
            }
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "folder.badge.plus", accessibilityDescription: "RightPlus")
            image?.isTemplate = true
            button.image = image
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "打开 RightPlus", action: #selector(showMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func showMainWindow() {
        NSApplication.shared.setActivationPolicy(.regular)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let window = NSApplication.shared.windows.first(where: { $0.canBecomeMain }) {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
            }
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func closeAllAppWindows() {
        for window in NSApplication.shared.windows where window.canBecomeMain {
            window.close()
        }
    }
}
