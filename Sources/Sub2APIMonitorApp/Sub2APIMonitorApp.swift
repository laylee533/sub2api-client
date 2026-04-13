import AppKit
import SwiftUI

@main
struct Sub2APIMonitorApp: App {
    @State private var model = AppModel()

    init() {
        SingleInstanceCoordinator.terminateOtherRunningInstances()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView(model: model)
        } label: {
            MenuBarStatusIcon(mode: model.statusItemIconMode)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
private enum SingleInstanceCoordinator {
    static func terminateOtherRunningInstances() {
        let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        let currentApp = NSRunningApplication.current

        if let bundleIdentifier = currentApp.bundleIdentifier {
            let duplicates = NSRunningApplication
                .runningApplications(withBundleIdentifier: bundleIdentifier)
                .filter { $0.processIdentifier != currentProcessIdentifier }

            duplicates.forEach { duplicate in
                duplicate.forceTerminate()
            }
            return
        }

        let localizedName = currentApp.localizedName ?? ProcessInfo.processInfo.processName
        let duplicates = NSWorkspace.shared.runningApplications.filter { app in
            app.processIdentifier != currentProcessIdentifier && app.localizedName == localizedName
        }

        duplicates.forEach { duplicate in
            duplicate.forceTerminate()
        }
    }
}
