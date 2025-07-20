import SwiftUI

struct LoadingView: View {
    @State private var loadingText = "Initializing TreeTop App..."
    @State private var dots = ""
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App icon or logo area
                Image(systemName: "tree")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .scaleEffect(1.0 + sin(Date().timeIntervalSinceReferenceDate * 2) * 0.1)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: Date().timeIntervalSinceReferenceDate)
                
                VStack(spacing: 16) {
                    Text("TreeTop")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.primary)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        .scaleEffect(1.2)

                    Text(loadingText + dots)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            startLoadingAnimation()
        }
    }
    
    private func startLoadingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.3)) {
                dots = dots.count >= 3 ? "" : dots + "."
            }
        }
    }
}

#Preview {
    LoadingView()
}
