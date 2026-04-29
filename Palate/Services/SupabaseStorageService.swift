//
//  SupabaseStorageService.swift
//  Palate
//

import UIKit
import Supabase

protocol ImageStorageService {
    func uploadAvatar(userId: String, image: UIImage) async throws -> String
    func deleteAvatar(path: String) async throws
}

final class SupabaseStorageService: ImageStorageService {
    private let bucketName = "avatars"
    
    func uploadAvatar(userId: String, image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImageConversion", code: -1, userInfo: [NSLocalizedDescriptionKey: "Не удалось конвертировать изображение"])
        }
        
        let filePath = "\(userId)/avatar.jpg"
        
        try await supabase.storage
            .from(bucketName)
            .upload(
                path: filePath,
                file: imageData,
                options: FileOptions(cacheControl: "3600", upsert: true)
            )
        
        let publicUrl = try await supabase.storage
            .from(bucketName)
            .getPublicURL(path: filePath)
        
        return publicUrl.absoluteString
    }
    
    func deleteAvatar(path: String) async throws {
        try await supabase.storage
            .from(bucketName)
            .remove(paths: [path])
    }
}
