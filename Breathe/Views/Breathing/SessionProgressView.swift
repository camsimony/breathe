import SwiftUI

struct SessionProgressView: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.06))

                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: max(geo.size.height, geo.size.width * progress))
            }
        }
    }
}
