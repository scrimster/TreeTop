import SwiftUI

struct PremiumBackground: View {
    var showAnimation: Bool = false
    
    var body: some View {
        ZStack {
            // Professional dark pine gradient
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.18, blue: 0.35),  // Dark navy blue
                    Color(red: 0.15, green: 0.22, blue: 0.38),  // Slightly lighter navy
                    Color(red: 0.18, green: 0.32, blue: 0.28),  // Navy-pine transition
                    Color(red: 0.15, green: 0.35, blue: 0.22),  // Pine transition
                    Color(red: 0.12, green: 0.30, blue: 0.18)   // Deep pine green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle overlay for depth
            LinearGradient(
                colors: [
                    Color.white.opacity(0.02),
                    Color.clear,
                    Color.black.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

struct PremiumCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct PremiumButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    @State private var isPressed = false
    
    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(0.6)
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
            .pressEvents(
                onPress: { isPressed = true },
                onRelease: { isPressed = false }
            )
    }
}