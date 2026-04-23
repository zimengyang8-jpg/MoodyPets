//
//  AIService.swift
//  MoodyPets
//
//  Created by Zimeng Yang on 4/21/26.
//

import Foundation
import FirebaseFunctions

class AIService {
    
    private static let functions = Functions.functions()
    
    static func analyzePet(imageURL: String) async throws -> PetAnalysis {
        
        let callable = functions.httpsCallable("analyzePetPhoto")
        
        let result = try await callable.call([
            "imageURL": imageURL
        ])
        
        guard let data = result.data as? [String: Any] else {
            throw NSError(domain: "AI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        let mood = data["mood"] as? String ?? "Unknown"
        let reason = data["reason"] as? String ?? "No reason"
        let suggestion = data["suggestion"] as? String ?? "No suggestion"
        
        return PetAnalysis(
            id: nil,
            userId: nil,
            imageURL: imageURL,
            mood: mood,
            reason: reason,
            suggestion: suggestion,
            createdAt: Date()
        )
    }
}
