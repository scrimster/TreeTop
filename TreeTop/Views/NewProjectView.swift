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
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.8)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
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
                    
                    Button(action: {
                        createProject()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Create Project")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial)
                                .opacity(0.9)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .opacity(0.8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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
