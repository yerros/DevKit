import SwiftUI

struct GlowingProgress: View {
    let value: Double // 0...100

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white.opacity(0.06))

                // Fill
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.29, green: 0.62, blue: 1.0),
                                     Color(red: 0.55, green: 0.36, blue: 0.96)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(min(value, 100) / 100.0))

                // Glass overlay
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: geo.size.width * CGFloat(min(value, 100) / 100.0))
            }
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
        }
        .frame(height: 8)
    }
}
