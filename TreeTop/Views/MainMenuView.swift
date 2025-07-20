import SwiftUI

enum MainMenuDestination: Hashable {
    case newProject
    case existingProjects
    case about
    case howTo
    //in the future adding two more cases for the about and how to pages
}

struct MainMenuView: View {
    @State var path: [MainMenuDestination] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // Animated forest background
                AnimatedForestBackground()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // App title with enhanced styling
                    VStack(spacing: 8) {
                        Text("🌲")
                            .font(.system(size: 60))
                        Text("TreeTop")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(red: 0.9, green: 1.0, blue: 0.95)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Forest Canopy Analysis")
                            .font(.subheadline)
                            .glassTextSecondary(opacity: 0.8)
                            .fontWeight(.medium)
                    }
                    .padding(.bottom, 20)

                    // Menu Buttons with enhanced styling
                    VStack(spacing: 16) {
                        MenuButton(emoji: "🌿", title: "About TreeTop") {
                            path.append(.about)
                        }

                        MenuButton(emoji: "📖", title: "How to Use App") {
                            path.append(.howTo)
                        }

                        MenuButton(emoji: "🌳", title: "New Project") {
                            path.append(.newProject)
                        }

                        MenuButton(emoji: "📁", title: "Existing Projects") {
                            path.append(.existingProjects)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationDestination(for: MainMenuDestination.self) { destination in
                switch destination {
                case .newProject:
                    NewProjectView(path: $path)
                case .existingProjects:
                    ExistingProjectView()
                case .about:
                    AboutTreeTopView()
                case .howTo:
                    HowToUseAppView()
                }
            }
        }
    }
}

struct MenuButton: View {
    let emoji: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        LiquidGlassButton(cornerRadius: 20, action: action) {
            VStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: 36))
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .glassText()
                    .multilineTextAlignment(.center)
            }
            .frame(width: 160, height: 80)
            .padding(.vertical, 8)
        }
    }
}

