import SwiftUI

struct MainMenuView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Text("TreeTop")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)

                // Menu Buttons
                MenuButton(title: "🌿 About TreeTop") {
                    // Navigate to About View
                }

                MenuButton(title: "📖 How to Use App") {
                    // Navigate to How-To View
                }

                MenuButton(title: "🌳 New Project") {
                    // Navigate to New Project View
                }

                MenuButton(title: "📁 Existing Projects") {
                    // Navigate to Project List View
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct MenuButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(Color.green)
                .cornerRadius(16)
                .font(.headline)
        }
        .padding(.horizontal)
    }
}

