//
//  Avatar.swift
//  Palate
//

import Foundation

struct AvatarUploadResponse: Decodable {
    let Key: String
    let Bucket: String
    let path: String?
}
