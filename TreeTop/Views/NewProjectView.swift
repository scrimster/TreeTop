import SwiftUI

struct NewProjectView: View {
    @Binding var path: [MainMenuDestination] //receives navigation path
    @State var projectName: String = ""
    @State var showDuplicateAlert = false
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        ZStack {
            // Breathing animated background
            AnimatedForestBackground()
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()
                
                // Header section
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
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
                    
                    Text("Create New Project")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .glassText()
                        .multilineTextAlignment(.center)
                    
                    Text("Enter a unique name for your project")
                        .font(.system(.body, design: .rounded))
                        .glassTextSecondary(opacity: 0.7)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Input section
                LiquidGlassCard(cornerRadius: 20) {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Project Name")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .glassText()
                            
                            TextField("Enter project name", text: $projectName)
                                .font(.system(.body, design: .rounded))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .liquidGlass(cornerRadius: 12, strokeOpacity: 0.15, shadowRadius: 4)
                                .glassText()
                        }
                        
                        LiquidGlassButton(cornerRadius: 14, action: {
                            let newProject = ProjectManager.shared.createProject(name: projectName, date: Date())
                            if newProject != nil {
                                path = [.existingProjects]
                                projectName = ""
                            } else {
                                showDuplicateAlert = true
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Create Project")
                                    .font(.system(.headline, design: .rounded, weight: .semibold))
                                    .glassText()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(20)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Project already exists", isPresented: $showDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A project with this name already exists. Please choose a different name.")
        }
        
        .onAppear {
            if let testImageURL = Bundle.main.url(forResource: "test-photo", withExtension: "jpg") {
                if let coordinate = PhotoCoordinates.extract(from: testImageURL) {
                    print("✅Coordinate extracted: \(coordinate.latitude), \(coordinate.longitude)")
                } else {
                    print("❌ Failed to extract coordinate.")
                }
            } else {
                print("❌Could not find test-photo.jpg in bundle")
            }
        }
        
//        .navigationDestination(item: $createdProject) {
//            project in LiveCameraView(project: project, shouldGoToExistingProjects: $shouldGoToExistingProjects)
//                .onAppear{
//                    print("navigating to camera")
//                }
//        }
//        
//        .navigationDestination(isPresented: $shouldGoToExistingProjects) {
//            ExistingProjectView()
//        }
    }
}

#Preview {
    NewProjectView(path: .constant([]))
}
