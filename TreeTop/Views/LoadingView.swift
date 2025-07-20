import SwiftUI

struct LoadingView: View {
    @State private var currentMessage = "Initializing TreeTop App..."
    @State private var dots = ""
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            // Use the same breathing background as the main app - ensures no flash  
            AnimatedForestBackground()
                .ignoresSafeArea()
            
            // Add a subtle overlay to ensure immediate visual feedback
            Color.clear
                .background(.ultraThinMaterial.opacity(0.1))
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // App logo with enhanced styling
                VStack(spacing: 16) {
                    // Tree icon with glow effect
                    Image(systemName: "tree.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.95, green: 1.0, blue: 0.98)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .white.opacity(0.5), radius: 10, x: 0, y: 0)
                    
                    Text("TreeTop")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.95, green: 1.0, blue: 0.98)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .white.opacity(0.4), radius: 4, x: 0, y: 0)
                }
                
                VStack(spacing: 20) {
                    // Simple progress view - no glass effects during startup
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)

                    Text(currentMessage + dots)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .glassText()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .frame(minHeight: 40)
                }
            }
        }
        .onAppear {
            print("🔄 LoadingView appeared")
            startLoadingAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onReceive(NotificationCenter.default.publisher(for: .initializationMessage)) { notification in
            if let message = notification.object as? String {
                currentMessage = message
            }
        }
    }
    
    private func startLoadingAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                dots = dots.count >= 3 ? "" : dots + "."
            }
        }
    }
}

// Extension to handle initialization messages
extension Notification.Name {
    static let initializationMessage = Notification.Name("initializationMessage")
}

#Preview {
    LoadingView()
}
