import SwiftUI

struct CustomizeSection: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsCard(title: "Coming soon") {
                    Text("Visual styles, overlay options, and other ways to make Breathe yours will show up here.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
