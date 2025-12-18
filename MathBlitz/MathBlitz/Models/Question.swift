import Foundation

struct Question: Identifiable, Equatable {
    let id = UUID()
    let multiplicand: Int
    let multiplier: Int
    let choices: [Int]
    let correctAnswerIndex: Int

    var questionText: String {
        "\(multiplicand) × \(multiplier)"
    }

    var correctAnswer: Int {
        multiplicand * multiplier
    }

    func isCorrect(choiceIndex: Int) -> Bool {
        choiceIndex == correctAnswerIndex
    }
}
