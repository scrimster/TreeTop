import SwiftUI

struct AnimatedForestBackground: View {
    @State private var animateLeaves = false
    @State private var leafOffsets: [CGPoint] = []
    @State private var leafRotations: [Double] = []
    @State private var leafOpacities: [Double] = []
    @State private var gradientAnimation = false
    
    // Configuration
    private let numberOfLeaves = 15
    private let leafColors: [Color] = [
        Color(red: 0.15, green: 0.4, blue: 0.2).opacity(0.5),  // Deep pine green
        Color(red: 0.1, green: 0.35, blue: 0.25).opacity(0.4), // Darker forest green
        Color(red: 0.2, green: 0.45, blue: 0.3).opacity(0.6),  // Medium pine
        Color(red: 0.05, green: 0.3, blue: 0.15).opacity(0.4), // Very dark pine
        Color(red: 0.12, green: 0.38, blue: 0.28).opacity(0.5) // Pine-teal mix
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Breathing vertical gradient - navy blue to pine green
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
                    .easeInOut(duration: 6.0)
                    .repeatForever(autoreverses: true),
                    value: gradientAnimation
                )
                
                // Subtle overlay for atmospheric depth
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),  // Light mist at top
                        Color.clear,
                        Color.clear,
                        Color.black.opacity(0.03)   // Subtle shadow at bottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Animated leaves
                ForEach(0..<numberOfLeaves, id: \.self) { index in
                    LeafView(
                        color: leafColors[index % leafColors.count],
                        size: CGSize(
                            width: Double.random(in: 8...16),
                            height: Double.random(in: 12...20)
                        )
                    )
                    .offset(
                        x: animateLeaves ? 
                            leafOffsets[safe: index]?.x ?? 0 : 
                            Double.random(in: -50...geometry.size.width + 50),
                        y: animateLeaves ? 
                            leafOffsets[safe: index]?.y ?? 0 : 
                            -50
                    )
                    .rotationEffect(.degrees(leafRotations[safe: index] ?? 0))
                    .opacity(leafOpacities[safe: index] ?? 0.5)
                    .animation(
                        .linear(duration: Double.random(in: 15...25))
                        .repeatForever(autoreverses: false)
                        .delay(Double.random(in: 0...10)),
                        value: animateLeaves
                    )
                }
            }
        }
        .onAppear {
            setupLeafProperties()
            startAnimation()
            // Start the breathing gradient animation
            withAnimation {
                gradientAnimation = true
            }
        }
    }
    
    private func setupLeafProperties() {
        leafOffsets = (0..<numberOfLeaves).map { _ in
            CGPoint(
                x: Double.random(in: -100...UIScreen.main.bounds.width + 100),
                y: UIScreen.main.bounds.height + 100
            )
        }
        
        leafRotations = (0..<numberOfLeaves).map { _ in
            Double.random(in: 0...360)
        }
        
        leafOpacities = (0..<numberOfLeaves).map { _ in
            Double.random(in: 0.2...0.6)
        }
    }
    
    private func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animateLeaves = true
        }
    }
}

struct LeafView: View {
    let color: Color
    let size: CGSize
    @State private var sway = false
    
    var body: some View {
        // Simple leaf shape using SF Symbols
        Image(systemName: "leaf.fill")
            .foregroundColor(color)
            .font(.system(size: min(size.width, size.height)))
            .scaleEffect(sway ? 1.1 : 0.9)
            .rotationEffect(.degrees(sway ? 5 : -5))
            .animation(
                .easeInOut(duration: Double.random(in: 2...4))
                .repeatForever(autoreverses: true),
                value: sway
            )
            .onAppear {
                sway = true
            }
    }
}

// Safe array access extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
