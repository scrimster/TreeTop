import SwiftUI

/// High-performance background alternative for better FPS on lower-end devices
struct PerformanceOptimizedBackground: View {
    @State private var gradientAnimation = false
    
    var body: some View {
        // Simple breathing gradient without complex overlays or animations
        LinearGradient(
            colors: gradientAnimation ? [
                Color(red: 0.08, green: 0.15, blue: 0.4),   // Deep navy blue at top
                Color(red: 0.06, green: 0.2, blue: 0.45),   // Darker navy
                Color(red: 0.08, green: 0.25, blue: 0.35),  // Navy-teal transition
                Color(red: 0.1, green: 0.3, blue: 0.25),    // Teal-pine transition
                Color(red: 0.12, green: 0.4, blue: 0.18)    // Vibrant pine green at bottom
            ] : [
                Color(red: 0.05, green: 0.12, blue: 0.35),  // Even deeper navy
                Color(red: 0.04, green: 0.18, blue: 0.4),   // Darker navy variation
                Color(red: 0.06, green: 0.22, blue: 0.32),  // Darker navy-teal
                Color(red: 0.08, green: 0.28, blue: 0.22),  // Darker teal-pine
                Color(red: 0.1, green: 0.35, blue: 0.15)    // Deeper pine green
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .animation(
            .easeInOut(duration: 12.0)  // Much slower animation for smoother performance
            .repeatForever(autoreverses: true),
            value: gradientAnimation
        )
        .onAppear {
            // Delay animation start to let UI settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    gradientAnimation = true
                }
            }
        }
    }
}

#Preview {
    PerformanceOptimizedBackground()
}
