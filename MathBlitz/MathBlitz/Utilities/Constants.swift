import SwiftUI

enum AppConstants {
    static let gameDuration: TimeInterval = 60
    static let numberOfChoices = 4

    enum Animation {
        static let quickDuration: Double = 0.2
        static let standardDuration: Double = 0.3
        static let slowDuration: Double = 0.5
    }

    enum Haptics {
        static let correctFeedback = UIImpactFeedbackGenerator(style: .medium)
        static let wrongFeedback = UINotificationFeedbackGenerator()
        static let buttonFeedback = UIImpactFeedbackGenerator(style: .light)
    }
}

enum Badge: String, CaseIterable {
    case firstGame = "Eerste Stappen"
    case score10 = "Dubbele Cijfers"
    case score20 = "Rekenwonder"
    case score30 = "Rekenmeester"
    case perfectStreak5 = "In Vuur"
    case perfectStreak10 = "Onstuitbaar"
    case allLevels = "Allrounder"

    var icon: String {
        switch self {
        case .firstGame: return "star.fill"
        case .score10: return "10.circle.fill"
        case .score20: return "20.circle.fill"
        case .score30: return "30.circle.fill"
        case .perfectStreak5: return "flame.fill"
        case .perfectStreak10: return "bolt.fill"
        case .allLevels: return "medal.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstGame: return .yellow
        case .score10: return .bronze
        case .score20: return .silver
        case .score30: return .gold
        case .perfectStreak5: return .orange
        case .perfectStreak10: return .red
        case .allLevels: return .purple
        }
    }

    var description: String {
        switch self {
        case .firstGame: return "Voltooi je eerste spel"
        case .score10: return "Scoor 10+ punten in een spel"
        case .score20: return "Scoor 20+ punten in een spel"
        case .score30: return "Scoor 30+ punten in een spel"
        case .perfectStreak5: return "Krijg 5 goede antwoorden op rij"
        case .perfectStreak10: return "Krijg 10 goede antwoorden op rij"
        case .allLevels: return "Speel alle moeilijkheidsniveaus"
        }
    }
}
