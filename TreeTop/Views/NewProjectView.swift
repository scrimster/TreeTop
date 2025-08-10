import SwiftUI

struct NewProjectView: View {
    @Binding var path: [MainMenuDestination] //receives navigation path
    @State var projectName: String = ""
    @State var showDuplicateAlert = false
    @StateObject private var locationManager = LocationManager()
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Breathing animated background
            AnimatedForestBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false) // Prevent background from intercepting touches

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
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .liquidGlass(cornerRadius: 12)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .submitLabel(.done)
                                .focused($isTextFieldFocused)
                                .onSubmit {
                                    // Handle return key - create project if name is valid
                                    if !projectName.trimmingCharacters(in: .whitespaces).isEmpty {
                                        createProject()
                                    }
                                }
                        }
                        
                        LiquidGlassButton(cornerRadius: 14, action: {
                            createProject()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Create Project")
                                    .font(.system(.headline, design: .rounded, weight: .semibold))
                            }
                            .glassText()
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
        .onAppear {
            // Defer LocationManager startup to prevent RTI race condition
            locationManager.startUpdating()
        }
        .onDisappear {
            // Stop location updates when view disappears
            locationManager.stopUpdating()
        }
        .alert("Project already exists", isPresented: $showDuplicateAlert) {
            Button("OK", role: .cancel) { 
                // Clear focus to prevent RTI issues
                isTextFieldFocused = false
            }
        } message: {
            Text("A project with this name already exists. Please choose a different name.")
        }
    }
    
    // MARK: - Helper Functions
    private func createProject() {
        // Dismiss keyboard first to prevent RTI issues
        isTextFieldFocused = false
        
        // Small delay to ensure keyboard dismissal completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let newProject = ProjectManager.shared.createProject(name: projectName, date: Date())
            if newProject != nil {
                path = [.existingProjects]
                projectName = ""
            } else {
                showDuplicateAlert = true
            }
        }
    }
}

#Preview {
    NewProjectView(path: .constant([]))
}
