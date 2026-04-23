//
//  PetPhotoVM.swift
//  MoodyPets
//
//  Created by Zimeng Yang on 4/22/26.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

class PetPhotoVM {
    static func saveImage(userId: String, analysisId: String, photo: PetPhoto, data: Data) async -> String? {
        let storage = Storage.storage().reference()
        let metadata = StorageMetadata()

        if photo.id == nil {
            photo.id = UUID().uuidString
        }

        metadata.contentType = "image/jpeg"

        // storage path for MoodyPets
        let path = "petPhotos/\(userId)/\(analysisId)/\(photo.id ?? "n/a").jpg"

        do {
            let storageRef = storage.child(path)
            let returnedMetaData = try await storageRef.putDataAsync(data, metadata: metadata)
            print("😎 SAVED! \(returnedMetaData)")

            guard let url = try? await storageRef.downloadURL() else {
                print("😡 ERROR: Could not get downloadURL")
                return nil
            }

            photo.imageURLString = url.absoluteString
            print("photo.imageURLString: \(photo.imageURLString)")

            return photo.imageURLString

        } catch {
            print("😡 ERROR saving photo to Storage \(error.localizedDescription)")
            return nil
        }
    }
}
