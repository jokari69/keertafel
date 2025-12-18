import Foundation

class QuestionGenerator {
    private let level: DifficultyLevel
    private var recentQuestions: [(Int, Int)] = []
    private let maxRecentQuestions = 5

    init(level: DifficultyLevel) {
        self.level = level
    }

    func generateQuestion() -> Question {
        let maxNum = level.maxNumber
        var multiplicand: Int
        var multiplier: Int

        // Generate unique question (avoid recent repeats)
        repeat {
            multiplicand = Int.random(in: 1...maxNum)
            multiplier = Int.random(in: 1...maxNum)
        } while recentQuestions.contains(where: { $0 == (multiplicand, multiplier) || $0 == (multiplier, multiplicand) })

        // Track recent questions
        recentQuestions.append((multiplicand, multiplier))
        if recentQuestions.count > maxRecentQuestions {
            recentQuestions.removeFirst()
        }

        let correctAnswer = multiplicand * multiplier
        let choices = generateChoices(correctAnswer: correctAnswer, maxNum: maxNum)
        let correctIndex = choices.firstIndex(of: correctAnswer) ?? 0

        return Question(
            multiplicand: multiplicand,
            multiplier: multiplier,
            choices: choices,
            correctAnswerIndex: correctIndex
        )
    }

    private func generateChoices(correctAnswer: Int, maxNum: Int) -> [Int] {
        var choices = Set<Int>()
        choices.insert(correctAnswer)

        // Generate plausible wrong answers
        let strategies: [() -> Int] = [
            // Off by one
            { correctAnswer + [-2, -1, 1, 2].randomElement()! },
            // Common mistake: add instead of multiply
            { Int.random(in: 1...maxNum) + Int.random(in: 1...maxNum) },
            // Different multiplication
            { Int.random(in: 1...maxNum) * Int.random(in: 1...maxNum) },
            // Percentage off
            { Int(Double(correctAnswer) * Double.random(in: 0.7...1.3)) },
            // Tens digit swap
            { self.swapDigits(correctAnswer) }
        ]

        while choices.count < 4 {
            let strategy = strategies.randomElement()!
            let wrongAnswer = strategy()

            // Ensure valid wrong answer
            if wrongAnswer > 0 && wrongAnswer != correctAnswer && wrongAnswer <= maxNum * maxNum {
                choices.insert(wrongAnswer)
            }
        }

        return Array(choices).shuffled()
    }

    private func swapDigits(_ number: Int) -> Int {
        guard number >= 10 else { return number + Int.random(in: 1...5) }
        let tens = (number / 10) % 10
        let ones = number % 10
        let hundreds = number / 100
        return hundreds * 100 + ones * 10 + tens
    }

    func reset() {
        recentQuestions.removeAll()
    }
}
