import SwiftUI

struct NewProjectView: View {
    @State var projectName: String = ""
    @State var createdProject: Project? = nil
    @State var shouldGoToExistingProjects = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Create New Project")
                .font(.title)
                .bold()
            
            // Project name input
            TextField("Enter project name", text: $projectName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: {
                let newProject = ProjectManager.shared.createProject(name: projectName, date: Date())
                if let newProject = newProject {
                    self.createdProject = newProject
                }
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text("Take Photo")
                        .bold()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top, 50)
        .navigationDestination(item: $createdProject) {
            project in LiveCameraView(project: project, shouldGoToExistingProjects: $shouldGoToExistingProjects)
                .onAppear{
                    print("navigating to camera")
                }
        }
        .navigationDestination(isPresented: $shouldGoToExistingProjects) {
            ExistingProjectView()
        }
    }
}

#Preview {
    NewProjectView()
}
