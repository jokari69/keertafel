import SwiftUI
import Combine

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentQuestion: Question
    @Published var score: Int = 0
    @Published var timeRemaining: TimeInterval = 60
    @Published var gameState: GameState = .ready
    @Published var questionsAnswered: Int = 0
    @Published var correctAnswers: Int = 0
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0

    // Animation states
    @Published var showCorrectAnimation: Bool = false
    @Published var showWrongAnimation: Bool = false
    @Published var shakeCount: Int = 0
    @Published var selectedAnswerIndex: Int? = nil
    @Published var isAnswerLocked: Bool = false

    // MARK: - Private Properties
    private let level: DifficultyLevel
    private let questionGenerator: QuestionGenerator
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var timerProgress: Double {
        timeRemaining / 60.0
    }

    var isTimeLow: Bool {
        timeRemaining <= 10
    }

    var accuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsAnswered) * 100
    }

    // MARK: - Initialization
    init(level: DifficultyLevel) {
        self.level = level
        self.questionGenerator = QuestionGenerator(level: level)
        self.currentQuestion = questionGenerator.generateQuestion()
    }

    // MARK: - Game Control
    func startGame() {
        resetGame()
        gameState = .playing
        startTimer()
        generateHapticFeedback(.medium)
    }

    func resetGame() {
        timer?.invalidate()
        timer = nil
        score = 0
        timeRemaining = 60
        questionsAnswered = 0
        correctAnswers = 0
        currentStreak = 0
        bestStreak = 0
        showCorrectAnimation = false
        showWrongAnimation = false
        shakeCount = 0
        selectedAnswerIndex = nil
        isAnswerLocked = false
        questionGenerator.reset()
        currentQuestion = questionGenerator.generateQuestion()
        gameState = .ready
    }

    func submitAnswer(choiceIndex: Int) {
        guard gameState == .playing && !isAnswerLocked else { return }

        isAnswerLocked = true
        selectedAnswerIndex = choiceIndex

        let isCorrect = currentQuestion.isCorrect(choiceIndex: choiceIndex)

        if isCorrect {
            handleCorrectAnswer()
        } else {
            handleWrongAnswer()
        }

        // Brief delay then next question
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.nextQuestion()
        }
    }

    // MARK: - Private Methods
    private func handleCorrectAnswer() {
        score += 1
        questionsAnswered += 1
        correctAnswers += 1
        currentStreak += 1
        bestStreak = max(bestStreak, currentStreak)

        showCorrectAnimation = true
        generateHapticFeedback(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showCorrectAnimation = false
        }
    }

    private func handleWrongAnswer() {
        score = max(0, score - 1)
        questionsAnswered += 1
        currentStreak = 0

        showWrongAnimation = true
        shakeCount += 1
        generateHapticFeedback(.error)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showWrongAnimation = false
        }
    }

    private func nextQuestion() {
        selectedAnswerIndex = nil
        isAnswerLocked = false
        currentQuestion = questionGenerator.generateQuestion()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }

    private func updateTimer() {
        timeRemaining -= 0.1

        if timeRemaining <= 0 {
            timeRemaining = 0
            endGame()
        }
    }

    private func endGame() {
        timer?.invalidate()
        timer = nil
        gameState = .finished
        generateHapticFeedback(.heavy)
    }

    private func generateHapticFeedback(_ style: HapticStyle) {
        switch style {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private enum HapticStyle {
        case light, medium, heavy, success, error
    }
}
