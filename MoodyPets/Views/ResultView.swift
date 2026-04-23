//
//  ResultView.swift
//  MoodyPets
//
//  Created by Zimeng Yang on 4/19/26.
//

import SwiftUI
import FirebaseAuth

struct ResultView: View {
    let petImage: Image?
    let petImageData: Data?
    let analysis: PetAnalysis
    let imageURL: String?
    
    @State private var notes = ""
    @State private var saveMessage: String?
    @State private var isSaving = false
    @Binding var shouldReset: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    if let petImage {
                        petImage
                            .resizable()
                            .scaledToFill()
                            .frame(height: 260)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(20)
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 260)
                            .overlay {
                                Text("No Image Available")
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mood Result")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(analysis.mood.capitalized)
                        .font(.system(size: 34, weight: .bold))
                    
                    Text("AI estimate based on visible posture and expression.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Why this result?")
                        .font(.headline)
                    
                    Text(analysis.reason)
                        .font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggested Action")
                        .font(.headline)
                    
                    Text(analysis.suggestion)
                        .font(.body)
                    
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.08))
                .cornerRadius(16)
                
                Text("Analyzed At: \(analysis.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Notes")
                        .font(.headline)
                    
                    TextField("Add context, like 'after a walk' or 'before dinner'", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.gray, lineWidth: 1)
                        }
                        .lineLimit(3...5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if let saveMessage {
                    Text(saveMessage)
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
                
                Button {
                    Task {
                        await saveResult()
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Save Analysis")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
                
                Button("Analyze Another Photo") {
                    shouldReset = true
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .padding(.vertical)
        }
        .navigationTitle("Analysis Result")
        .navigationBarTitleDisplayMode(.large)
    }
    
    func saveResult() async {
        isSaving = true
        saveMessage = nil
        
        guard let userId = Auth.auth().currentUser?.uid else {
            isSaving = false
            saveMessage = "No logged-in user."
            return
        }
        var imageURL: String? = nil
        
        if let petImageData {
            let photo = PetPhoto(description: notes)
            let analysisId = analysis.id ?? UUID().uuidString
            
            imageURL = await PetPhotoVM.saveImage(
                userId: userId,
                analysisId: analysisId,
                photo: photo,
                data: petImageData
            )
        }
        
        let finalAnalysis = PetAnalysis(
            id: analysis.id,
            userId: userId,
            imageURL: imageURL,
            mood: analysis.mood,
            reason: analysis.reason,
            suggestion: analysis.suggestion,
            notes: notes.isEmpty ? nil : notes,
            createdAt: analysis.createdAt
        )
        
        let savedID = await PetAnalysisVM.saveAnalysis(analysis: finalAnalysis)
        
        isSaving = false

        if savedID != nil {
            saveMessage = "Analysis saved successfully."
        } else {
            saveMessage = "Failed to save analysis."
        }
    }
}

#Preview {
    NavigationStack {
        ResultView(
            petImage: nil,
            petImageData: nil,
            analysis: PetAnalysis(
                id: nil,
                userId: nil,
                imageURL: nil,
                mood: "Happy",
                reason: "Relaxed posture and alert eyes",
                suggestion: "Great time for play or training",
                createdAt: Date()
            ),
            imageURL: nil,
            shouldReset: .constant(false)
        )
    }
}
