import SwiftUI

/// Adaptive background that automatically chooses the best background for performance
struct AdaptiveForestBackground: View {
    @StateObject private var performanceSettings = PerformanceSettings.shared
    
    var body: some View {
        Group {
            if performanceSettings.simplifiedBackgrounds {
                SimpleForestBackground()
            } else if performanceSettings.useHighPerformanceMode {
                PerformanceOptimizedBackground()
            } else {
                AnimatedForestBackground()
            }
        }
    }
}

#Preview {
    AdaptiveForestBackground()
}
