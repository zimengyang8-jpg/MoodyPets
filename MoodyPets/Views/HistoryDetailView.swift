//
//  HistoryDetailView.swift
//  MoodyPets
//
//  Created by Zimeng Yang on 4/23/26.
//

import SwiftUI

struct HistoryDetailView: View {
    let analysis: PetAnalysis

    var body: some View {
        ZStack {
            Color.accentColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    if let imageURL = analysis.imageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 260)
                                    .overlay {
                                        ProgressView()
                                    }

                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 260)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(20)

                            case .failure:
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 260)
                                    .overlay {
                                        Text("Image Unavailable")
                                            .foregroundStyle(.secondary)
                                    }

                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.themeblue.opacity(0.15))
                            .frame(height: 260)
                            .overlay {
                                Text("No Image Available")
                                    .foregroundStyle(.themeblue)
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood Result")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(analysis.mood.capitalized)
                            .font(.system(size: 34, weight: .bold))

                        Text("Saved AI estimate based on visible posture and expression.")
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

                    if let notes = analysis.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Notes")
                                .font(.headline)

                            Text(notes)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical)
            }
        }
        .navigationTitle("Saved Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HistoryDetailView(
            analysis: PetAnalysis(
                id: nil,
                userId: "previewUser",
                imageURL: nil,
                mood: "happy",
                reason: "Relaxed posture and alert eyes",
                suggestion: "Great time for play or training",
                notes: "After lunch and before a walk.",
                createdAt: Date()
            )
        )
    }
}
