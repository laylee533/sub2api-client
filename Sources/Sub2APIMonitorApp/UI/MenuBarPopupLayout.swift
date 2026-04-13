import CoreGraphics

enum MenuBarPopupLayout {
    static let minimumHeight: CGFloat = 280
    static let maximumHeight: CGFloat = 540

    static func preferredHeight(for contentHeight: CGFloat) -> CGFloat {
        min(max(contentHeight, minimumHeight), maximumHeight)
    }
}
