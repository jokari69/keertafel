import SwiftUI

enum DifficultyLevel: String, CaseIterable, Codable, Identifiable {
    case upTo10 = "10"
    case upTo12 = "12"
    case upTo15 = "15"
    case upTo20 = "20"

    var id: String { rawValue }

    var maxNumber: Int {
        switch self {
        case .upTo10: return 10
        case .upTo12: return 12
        case .upTo15: return 15
        case .upTo20: return 20
        }
    }

    var displayName: String {
        "Tot \(rawValue)"
    }

    var shortName: String {
        "×\(rawValue)"
    }

    var color: Color {
        switch self {
        case .upTo10: return .green
        case .upTo12: return .blue
        case .upTo15: return .orange
        case .upTo20: return .red
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .upTo10:
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .upTo12:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .upTo15:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .upTo20:
            return LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var icon: String {
        switch self {
        case .upTo10: return "star.fill"
        case .upTo12: return "star.leadinghalf.filled"
        case .upTo15: return "flame.fill"
        case .upTo20: return "bolt.fill"
        }
    }

    var difficulty: String {
        switch self {
        case .upTo10: return "Makkelijk"
        case .upTo12: return "Gemiddeld"
        case .upTo15: return "Moeilijk"
        case .upTo20: return "Expert"
        }
    }
}
