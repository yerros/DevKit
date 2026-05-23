import SwiftUI

struct StatusDot: View {
    let state: ServiceState

    var color: Color {
        switch state {
        case .running: return Color(red: 0.20, green: 0.83, blue: 0.60)
        case .stopped: return Color(red: 0.97, green: 0.44, blue: 0.44)
        case .starting: return Color(red: 0.98, green: 0.75, blue: 0.15)
        case .error: return Color(red: 0.97, green: 0.44, blue: 0.44)
        case .unknown: return Color(red: 0.42, green: 0.45, blue: 0.50)
        }
    }

    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .shadow(color: color.opacity(0.6), radius: 6, x: 0, y: 0)
            .scaleEffect(state == .starting && isPulsing ? 1.2 : 1.0)
            .animation(
                state == .starting
                    ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .onAppear {
                if state == .starting { isPulsing = true }
            }
            .onChange(of: state) { newState in
                isPulsing = newState == .starting
            }
            .accessibilityLabel(state.rawValue)
    }
}
