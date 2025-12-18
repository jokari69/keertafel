import Foundation
import SwiftUI

@MainActor
class UserService: ObservableObject {
    @Published var username: String {
        didSet {
            UserDefaults.standard.set(username, forKey: "mathblitz_username")
        }
    }

    @Published var showingUsernamePrompt = false

    static let shared = UserService()

    init() {
        if let saved = UserDefaults.standard.string(forKey: "mathblitz_username"), !saved.isEmpty {
            self.username = saved
        } else {
            self.username = ""
            self.showingUsernamePrompt = true
        }
    }

    var hasUsername: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func setUsername(_ name: String) {
        username = name.trimmingCharacters(in: .whitespacesAndNewlines)
        showingUsernamePrompt = false
    }
}
