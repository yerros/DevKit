import SwiftUI

struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var isMonospaced: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(isMonospaced ? .system(size: 12, design: .monospaced) : .system(size: 12))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        isFocused ? Color(red: 0.29, green: 0.62, blue: 1.0).opacity(0.4) : Color.white.opacity(0.1),
                        lineWidth: 0.5
                    )
            )
            .focused($isFocused)
    }
}
