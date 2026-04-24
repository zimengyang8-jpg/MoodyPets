//
//  HistoryView.swift
//  MoodyPets
//
//  Created by Zimeng Yang on 4/23/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HistoryView: View {
    @State private var analyses: [PetAnalysis] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.accentColor
                .ignoresSafeArea()
            
            List(analyses, id: \.id) { analysis in
                NavigationLink {
                    HistoryDetailView(analysis: analysis)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(analysis.mood.capitalized)
                            .font(.headline)
                        
                        Text(analysis.reason)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        
                        Text(analysis.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task {
                            await deleteAnalysis(analysis)
                        }
                    }
                }
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("History")
        .overlay {
            if isLoading {
                ProgressView("Loading...")
            } else if analyses.isEmpty {
                ContentUnavailableView(
                    "No Saved Analyses",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Your saved pet mood analyses will appear here.")
                )
            }
        }
        .task {
            await loadAnalyses()
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    func loadAnalyses() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No logged-in user."
            return
        }
        print("Current logged-in uid: \(userId)")
        isLoading = true
        errorMessage = nil
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("analyses")
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            print("Matched document count: \(snapshot.documents.count)")
            for doc in snapshot.documents {
                print("Matched doc id: \(doc.documentID)")
                print(doc.data())
            }
            
            analyses = snapshot.documents.compactMap { doc in
                do {
                    return try doc.data(as: PetAnalysis.self)
                } catch {
                    print("Decode failed for doc \(doc.documentID): \(error)")
                    return nil
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteAnalysis(_ analysis: PetAnalysis) async {
        guard let id = analysis.id else {
            errorMessage = "Missing document ID."
            return
        }

        do {
            try await Firestore.firestore()
                .collection("analyses")
                .document(id)
                .delete()

            analyses.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
            print("Delete error: \(error)")
        }
    }
}

#Preview {
    HistoryView()
}
