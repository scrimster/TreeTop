import SwiftUI

enum MainMenuDestination: Hashable {
    case newProject
    case existingProjects
    //in the future adding two more cases for the about and how to pages
}

struct MainMenuView: View {
    @State var path: [MainMenuDestination] = []
    
    var body: some View {
        NavigationStack(path: $path) {
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
                    path.append(.newProject)
                }

                MenuButton(title: "📁 Existing Projects") {
                    path.append(.existingProjects)
                }

                Spacer()
            }
            .padding()
            .navigationDestination(for: MainMenuDestination.self) { destination in
                switch destination {
                case .newProject:
                    NewProjectView(path: $path)
                case .existingProjects:
                    ExistingProjectView()
                }
            }
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

