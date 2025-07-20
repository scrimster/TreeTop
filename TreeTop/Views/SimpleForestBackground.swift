import SwiftUI

struct SimpleForestBackground: View {
    var body: some View {
        // Static gradient for immediate loading - no animations
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.15, blue: 0.4),   // Deep navy blue at top
                Color(red: 0.06, green: 0.2, blue: 0.45),   // Darker navy
                Color(red: 0.08, green: 0.25, blue: 0.35),  // Navy-teal transition
                Color(red: 0.1, green: 0.3, blue: 0.25),    // Teal-pine transition
                Color(red: 0.12, green: 0.4, blue: 0.18)    // Vibrant pine green at bottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
