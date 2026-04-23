//
//  HomeView.swift
//  MoodyPets
//
//  Created by Zimeng Yang on 4/19/26.
//

import SwiftUI
import PhotosUI
import FirebaseAuth

@MainActor
struct HomeView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var selectedImageData: Data?
    @State private var isAnalyzing = false
    @State private var navigateToResult = false
    @State private var shouldReset = false
    @State private var analysisResult: PetAnalysis?
    @State private var uploadedImageURL: String?
    
    var body: some View {
        VStack {
            Spacer()
            if let selectedImage {
                selectedImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .frame(height: 250)
                    .overlay(Text("Upload an Image to Start!"))
            }
            
            PhotosPicker(selection: $selectedItem, matching: .images, preferredItemEncoding: .automatic) {
                Label("Photo Library", systemImage: "photo.fill.on.rectangle.fill")
            }
            .padding(.vertical)
            .bold()
            .tint(.purple)
            
            Spacer()
            Spacer()
            
            Button {
                Task {
                    await runAnalysis()
                }
            } label: {
                if isAnalyzing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Analyze Mood")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
            }
            .tint(.purple)
            .buttonStyle(.borderedProminent)
            .disabled(selectedImageData == nil || isAnalyzing)
            
        }
        .padding()
        .navigationTitle("MoodyPets")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Sign Out") {
                    do {
                        try Auth.auth().signOut()
                        print("✅ Logged out")
                    } catch {
                        print("❌ Logout failed:", error)
                    }
                }
            }
        }
        .task(id: selectedItem) {
            if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                selectedImageData = data
                
                if let uiImage = UIImage(data: data) {
                    selectedImage = Image(uiImage: uiImage)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToResult) {
            if let analysisResult {
                ResultView(
                    petImage: selectedImage,
                    petImageData: selectedImageData,
                    analysis: analysisResult,
                    imageURL: uploadedImageURL,
                    shouldReset: $shouldReset
                )
            }
        }
        .onChange(of: shouldReset) { _, newValue in
            if newValue {
                selectedItem = nil
                selectedImage = nil
                analysisResult = nil
                uploadedImageURL = nil
                navigateToResult = false
                shouldReset = false
            }
        }
    }
    
    func runAnalysis() async {
        guard let imageData = selectedImageData else { return }

        isAnalyzing = true

        do {
            let imageURL = try await uploadImageToFirebase(data: imageData)
            let analysis = try await AIService.analyzePet(imageURL: imageURL)

            uploadedImageURL = imageURL
            analysisResult = analysis
            navigateToResult = true
        } catch {
            print("AI error: \(error)")
        }

        isAnalyzing = false
    }
    
    func uploadImageToFirebase(data: Data) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Upload", code: 1, userInfo: [NSLocalizedDescriptionKey: "No logged-in user"])
        }

        let photo = PetPhoto()
        let analysisId = UUID().uuidString

        guard let imageURL = await PetPhotoVM.saveImage(
            userId: userId,
            analysisId: analysisId,
            photo: photo,
            data: data
        ) else {
            throw NSError(domain: "Upload", code: 2, userInfo: [NSLocalizedDescriptionKey: "Image upload failed"])
        }

        return imageURL
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
