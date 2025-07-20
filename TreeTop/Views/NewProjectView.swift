import SwiftUI

struct NewProjectView: View {
    @Binding var path: [MainMenuDestination] //receives navigation path
    @State var projectName: String = ""
    //@State var createdProject: Project? = nil
    //@State var shouldGoToExistingProjects = false
    @State var showDuplicateAlert = false
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Create a Project Name")
                .font(.title)
                .bold()
            
            // Project name input
            TextField("Enter project name", text: $projectName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: {
                var locationModel: LocationModel? = nil
                
                if let location = locationManager.currentLocation {
                    locationModel = LocationModel(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                }
                
                let newProject = ProjectManager.shared.createProject(name: projectName, date: Date())
                if newProject != nil {
                    path = [.existingProjects]
                    projectName = ""
                } else {
                    showDuplicateAlert = true
                }
            }) {
                HStack {
                    Image(systemName: "folder.badge.plus")
                    Text("Create Project")
                        .bold()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty)
            
            Spacer()
        }
        .navigationTitle("New Project Creation")
        .padding(.top, 50)
        .alert("Project already exists", isPresented: $showDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A project with this name already exists. Please choose a different name.")
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
