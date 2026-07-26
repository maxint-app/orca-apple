import SwiftUI

struct PaywallHeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.purple.opacity(0.15))
                    .frame(width: 64, height: 64)
                Text("\u{2605}")
                    .font(.system(size: 32))
                    .foregroundStyle(.purple)
            }

            Text("Unlock Premium")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Get access to all features and remove ads")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }
}
