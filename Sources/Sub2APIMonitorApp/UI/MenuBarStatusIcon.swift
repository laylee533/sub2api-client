import SwiftUI

enum StatusItemIconMode: Equatable {
    case setup
    case configured
}

private struct PixelSegment {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}

struct MenuBarStatusIcon: View {
    let mode: StatusItemIconMode

    private let iconSize = CGSize(width: 12, height: 10)

    var body: some View {
        Canvas { context, size in
            let origin = CGPoint(
                x: floor((size.width - iconSize.width) / 2),
                y: floor((size.height - iconSize.height) / 2)
            )

            for segment in segments {
                let rect = CGRect(
                    x: origin.x + segment.x,
                    y: origin.y + segment.y,
                    width: segment.width,
                    height: segment.height
                )
                context.fill(Path(rect), with: .foreground)
            }
        }
        .frame(width: 18, height: 14)
        .accessibilityLabel("sub2api 监控器")
        .help(mode == .configured ? "sub2api 监控器" : "sub2api 监控器（未配置）")
    }

    private var segments: [PixelSegment] {
        let shell = [
            PixelSegment(x: 1, y: 0, width: 10, height: 1),
            PixelSegment(x: 0, y: 1, width: 1, height: 7),
            PixelSegment(x: 11, y: 1, width: 1, height: 7),
            PixelSegment(x: 1, y: 7, width: 10, height: 1),
            PixelSegment(x: 4, y: 8, width: 4, height: 1),
            PixelSegment(x: 3, y: 9, width: 6, height: 1)
        ]

        switch mode {
        case .setup:
            return shell + [
                PixelSegment(x: 3, y: 3, width: 5, height: 1),
                PixelSegment(x: 8, y: 3, width: 1, height: 1),
                PixelSegment(x: 3, y: 5, width: 4, height: 1)
            ]
        case .configured:
            return shell + [
                PixelSegment(x: 3, y: 2, width: 2, height: 1),
                PixelSegment(x: 5, y: 2, width: 1, height: 1),
                PixelSegment(x: 7, y: 2, width: 2, height: 1),
                PixelSegment(x: 3, y: 4, width: 4, height: 1),
                PixelSegment(x: 3, y: 5, width: 2, height: 1),
                PixelSegment(x: 5, y: 5, width: 3, height: 1)
            ]
        }
    }
}

#Preview("Configured") {
    MenuBarStatusIcon(mode: .configured)
        .padding()
}

#Preview("Setup") {
    MenuBarStatusIcon(mode: .setup)
        .padding()
}
