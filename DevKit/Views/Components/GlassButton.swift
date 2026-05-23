import SwiftUI

enum GlassButtonStyle {
    case primary
    case destructive
    case ghost
}

struct GlassButton: View {
    let title: String
    let style: GlassButtonStyle
    let action: () -> Void
    var disabled: Bool = false
    var isLoading: Bool = false

    @State private var isHovered = false

    init(_ title: String, style: GlassButtonStyle = .primary, disabled: Bool = false, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.disabled = disabled
        self.isLoading = isLoading
        self.action = action
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .destructive: return Color(red: 0.97, green: 0.44, blue: 0.44)
        case .ghost: return .white.opacity(0.8)
        }
    }

    private var glowColor: Color {
        switch style {
        case .primary: return Color(red: 0.29, green: 0.62, blue: 1.0)
        case .destructive: return Color(red: 0.97, green: 0.44, blue: 0.44)
        case .ghost: return .white
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 12, height: 12)
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(disabled ? .white.opacity(0.3) : foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            .shadow(color: isHovered ? glowColor.opacity(0.3) : .clear, radius: 8, x: 0, y: 0)
        }
        .buttonStyle(.plain)
        .disabled(disabled || isLoading)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
