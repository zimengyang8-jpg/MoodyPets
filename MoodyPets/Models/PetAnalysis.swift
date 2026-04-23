//
//  PetAnalysis.swift
//  MoodyPets
//
//  Created by Zimeng Yang on 4/19/26.
//

import Foundation
import FirebaseFirestore

struct PetAnalysis: Codable, Identifiable {
    @DocumentID var id: String?
    
    var userId: String?
    var imageURL: String?
    
    var mood: String
    var reason: String
    var suggestion: String
    var notes: String?
    var createdAt: Date
}

