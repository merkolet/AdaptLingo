//
//  ProfileImageManager.swift
//  AdaptLingo
//

import UIKit
import Combine

final class ProfileImageManager: ObservableObject {
    static let shared = ProfileImageManager()

    @Published var avatarImage: UIImage? = nil
    private var currentUserId: String = ""
    private var key: String { "user_avatar_\(currentUserId)" }

    private init() {}

    func configure(userId: String) {
        guard userId != currentUserId else { return }
        currentUserId = userId
        if let data = UserDefaults.standard.data(forKey: key),
           let img = UIImage(data: data) {
            avatarImage = img
        } else {
            avatarImage = nil
        }
    }

    func save(_ image: UIImage) {
        avatarImage = image
        if let data = image.jpegData(compressionQuality: 0.75) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func reset() {
        avatarImage = nil
        currentUserId = ""
    }

}
