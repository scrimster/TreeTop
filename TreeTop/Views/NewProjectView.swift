import SwiftUI

struct NewProjectView: View {
    @State private var projectName: String = ""
    @State private var showCamera = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Create New Project")
                .font(.title)
                .bold()

            // Project name input
            TextField("Enter project name", text: $projectName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // Take photo button
            Button(action: {
                showCamera = true
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
        .sheet(isPresented: $showCamera) {
            // Replace with your actual camera view
            Text("Camera goes here")
        }
    }
}

