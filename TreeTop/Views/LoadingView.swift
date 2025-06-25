import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
                    .scaleEffect(1.5)

                Text("Welcome to the TreeTop App…")
                    .font(.headline)
                    .bold()
                    .foregroundColor(.secondary)
            }
        }
    }
}
#Preview {
    LoadingView()
}


/*
 #Preview {
 LoadingView()
 #PreviewLayout(.fixed(width: 300, height: 400))
 #PreviewLayout(.fixed(width: 600, height: 800))
 #PreviewLayout(.fixed(width: 800, height: 1000))
 #PreviewLayout(.fullScreen)
 #PreviewLayout(.sizeThatFits)
 
}
 */
