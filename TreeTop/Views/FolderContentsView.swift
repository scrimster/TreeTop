//
//  FolderContentsView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/29/25.
//

import SwiftUI

struct FolderContentsView: View {
    let folderURL: URL?
    @State var files: [String] = []
    var body: some View {
        List(files, id: \.self) { file in
            if file.lowercased().hasSuffix(".jpg") {
                NavigationLink(destination: ImageViewerView(imageURL: folderURL?.appendingPathComponent(file))) {
                    Text(file)
                }
            } else {
                Text(file)
            }
        }
        .navigationTitle("folder contents")
        .onAppear{
            loadFolderContents()
        }
    }
    
    func loadFolderContents() {
        guard let folderURL = folderURL else{return}
        do {
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            self.files = fileNames
        } catch {
            print("failed to read folder: \(error)")
        }
    }
    
    struct ImageViewerView : View {
        let imageURL: URL?
        
        var body: some View {
            if let url = imageURL, let uiImage = UIImage(contentsOfFile: url.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .navigationTitle(url.lastPathComponent)
                    .padding()
            } else {
                Text("could not load image.")
                    .foregroundColor(.red)
            }
        }
    }
}


#Preview {
    FolderContentsView(folderURL: nil)
}
