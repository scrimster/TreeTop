import SwiftUI

struct LoadingView: View {
    @State private var currentMessage = "Initializing TreeTop App..."
    @State private var dots = ""
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Simplified app icon
                Image(systemName: "tree")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                VStack(spacing: 16) {
                    Text("TreeTop")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.primary)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        .scaleEffect(1.2)

                    Text(currentMessage + dots)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
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
