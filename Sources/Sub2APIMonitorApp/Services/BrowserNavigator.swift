import AppKit
import Foundation

enum BrowserNavigator {
    static func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
