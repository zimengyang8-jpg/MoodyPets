//
//  PetAnalysisVM.swift
//  MoodyPets
//
//  Created by Zimeng Yang on 4/22/26.
//

import Foundation
import FirebaseFirestore

@Observable
class PetAnalysisVM {
    static func saveAnalysis(analysis: PetAnalysis) async -> String? {
        let db = Firestore.firestore()
        
        if let id = analysis.id {
            do {
                try db.collection("analyses").document(id).setData(from: analysis)
                print("😎 Data updated successfully!")
                return id
            } catch {
                print("😡 Could not update data in 'analyses' \(error.localizedDescription)")
                return id
            }
        } else {
            do {
                let docRef = try db.collection("analyses").addDocument(from: analysis)
                print("🐣 Data added successfully!")
                return docRef.documentID
            } catch {
                print("😡 Could not create a new analysis in 'analyses' \(error.localizedDescription)")
                return nil
            }
        }
    }
}
