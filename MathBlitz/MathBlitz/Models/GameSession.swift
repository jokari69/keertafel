import Foundation

enum GameState: Equatable {
    case ready
    case playing
    case finished
}

struct GameSession {
    var state: GameState = .ready
    var score: Int = 0
    var questionsAnswered: Int = 0
    var correctAnswers: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var timeRemaining: TimeInterval = 60

    mutating func answerCorrectly() {
        score += 1
        questionsAnswered += 1
        correctAnswers += 1
        currentStreak += 1
        bestStreak = max(bestStreak, currentStreak)
    }

    mutating func answerIncorrectly() {
        score = max(0, score - 1)
        questionsAnswered += 1
        currentStreak = 0
    }

    mutating func reset() {
        state = .ready
        score = 0
        questionsAnswered = 0
        correctAnswers = 0
        currentStreak = 0
        bestStreak = 0
        timeRemaining = 60
    }
}
