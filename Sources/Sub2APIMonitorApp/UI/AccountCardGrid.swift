import SwiftUI

struct AccountCardGrid: View {
    let cards: [AccountCardModel]

    var body: some View {
        if cards.isEmpty {
            ContentUnavailableView("当前筛选没有账号", systemImage: "tray")
                .frame(maxWidth: .infinity, minHeight: 140)
        } else {
            LazyVStack(spacing: 6) {
                ForEach(cards) { card in
                    AccountCardView(card: card)
                }
            }
        }
    }
}
