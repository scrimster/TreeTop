import SwiftUI

enum MainMenuDestination: Hashable {
    case newProject
    case existingProjects
    case about
    case howTo
    case map
}

struct MainMenuView: View {
    @State var path: [MainMenuDestination] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // Animated forest background
                AnimatedForestBackground()
                    .allowsHitTesting(false) // Prevent background from intercepting touches
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // App title with enhanced styling
                    VStack(spacing: 8) {
                        // Tree icon without glow effect
                        Image(systemName: "tree.fill")
                            .font(.system(size: 60))
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
                        // Large New Project button
                        LargeMenuButton(icon: "plus.circle.fill", title: "New Project") {
                            path.append(.newProject)
                        }

                        // Smaller rectangular buttons
                        SmallMenuButton(icon: "folder.fill", title: "Existing Projects") {
                            path.append(.existingProjects)
                        }
                        
                        SmallMenuButton(icon: "map.fill", title: "Map Viewer") {
                            path.append(.map)
                        }

                        SmallMenuButton(icon: "book.fill", title: "How to Use App") {
                            path.append(.howTo)
                        }

                        SmallMenuButton(icon: "info.circle.fill", title: "About TreeTop") {
                            path.append(.about)
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
                case .map:
                    MapScreen()
                }
            }
        }
    }
}

struct LargeMenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        LiquidGlassButton(cornerRadius: 20, action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.95, blue: 0.7),
                                Color(red: 0.2, green: 0.8, blue: 0.4),
                                Color(red: 0.1, green: 0.6, blue: 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .glassText()
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}

struct SmallMenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        LiquidGlassButton(cornerRadius: 16, action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .glassText()
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
}
