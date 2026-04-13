import AppKit
import SwiftUI

@MainActor
final class SettingsWindowCoordinator: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowCoordinator()

    private var windowController: NSWindowController?

    func show(model: AppModel) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let windowController = existingOrNewWindowController(model: model)
        let window = windowController.window

        windowController.showWindow(nil)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        windowController = nil
        NSApp.setActivationPolicy(.accessory)
    }

    private func existingOrNewWindowController(model: AppModel) -> NSWindowController {
        if let windowController {
            if let hostingController = windowController.contentViewController as? NSHostingController<SettingsView> {
                hostingController.rootView = SettingsView(model: model)
            }
            return windowController
        }

        let hostingController = NSHostingController(rootView: SettingsView(model: model))
        let window = NSWindow(contentViewController: hostingController)
        window.title = "设置"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.tabbingMode = .disallowed
        window.level = .floating
        window.collectionBehavior = [.moveToActiveSpace]
        window.setContentSize(NSSize(width: 520, height: 520))

        let windowController = NSWindowController(window: window)
        self.windowController = windowController
        return windowController
    }
}
