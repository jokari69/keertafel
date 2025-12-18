import SwiftUI
import SwiftData
import Combine

@MainActor
class HighScoreViewModel: ObservableObject {
    @Published var todayScores: [DifficultyLevel: HighScore?] = [:]
    @Published var allTimeScores: [DifficultyLevel: HighScore?] = [:]
    @Published var recentScores: [HighScore] = []

    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupNotificationObserver()
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refreshScores()
    }

    func refreshScores() {
        guard let modelContext else { return }

        for level in DifficultyLevel.allCases {
            todayScores[level] = fetchBestScore(for: level, isToday: true, context: modelContext)
            allTimeScores[level] = fetchBestScore(for: level, isToday: false, context: modelContext)
        }

        recentScores = fetchRecentScores(context: modelContext)
    }

    func saveScoreLocally(
        score: Int,
        level: DifficultyLevel,
        questionsAnswered: Int,
        correctAnswers: Int
    ) {
        guard let modelContext else { return }

        let highScore = HighScore(
            score: score,
            level: level,
            questionsAnswered: questionsAnswered,
            correctAnswers: correctAnswers
        )

        modelContext.insert(highScore)

        do {
            try modelContext.save()
            refreshScores()
        } catch {
            print("Failed to save score: \(error)")
        }
    }

    func getBestScore(for level: DifficultyLevel, isToday: Bool) -> Int? {
        if isToday {
            return todayScores[level]??.score
        } else {
            return allTimeScores[level]??.score
        }
    }

    func isNewHighScore(score: Int, level: DifficultyLevel, isToday: Bool) -> Bool {
        guard let bestScore = getBestScore(for: level, isToday: isToday) else {
            return true
        }
        return score > bestScore
    }

    func getScoresForLevel(_ level: DifficultyLevel) -> [HighScore] {
        guard let modelContext else { return [] }

        let levelString = level.rawValue
        let descriptor = FetchDescriptor<HighScore>(
            predicate: #Predicate { $0.level == levelString },
            sortBy: [SortDescriptor(\.score, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch scores: \(error)")
            return []
        }
    }

    // MARK: - Private Methods

    private func fetchBestScore(for level: DifficultyLevel, isToday: Bool, context: ModelContext) -> HighScore? {
        let levelString = level.rawValue

        var descriptor: FetchDescriptor<HighScore>

        if isToday {
            let startOfDay = Calendar.current.startOfDay(for: Date())
            descriptor = FetchDescriptor<HighScore>(
                predicate: #Predicate { $0.level == levelString && $0.date >= startOfDay },
                sortBy: [SortDescriptor(\.score, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<HighScore>(
                predicate: #Predicate { $0.level == levelString },
                sortBy: [SortDescriptor(\.score, order: .reverse)]
            )
        }

        descriptor.fetchLimit = 1

        do {
            let results = try context.fetch(descriptor)
            return results.first
        } catch {
            print("Failed to fetch best score: \(error)")
            return nil
        }
    }

    private func fetchRecentScores(context: ModelContext) -> [HighScore] {
        var descriptor = FetchDescriptor<HighScore>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 10

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch recent scores: \(error)")
            return []
        }
    }

    private func setupNotificationObserver() {
        NotificationCenter.default.publisher(for: .cloudKitScoresFetched)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let remoteScores = notification.object as? [HighScore] {
                    self?.mergeRemoteScores(remoteScores)
                }
            }
            .store(in: &cancellables)
    }

    private func mergeRemoteScores(_ remoteScores: [HighScore]) {
        guard let modelContext else { return }

        for remoteScore in remoteScores {
            // Check if this score already exists locally
            let localID = remoteScore.id
            let descriptor = FetchDescriptor<HighScore>(
                predicate: #Predicate { $0.id == localID }
            )

            do {
                let existingScores = try modelContext.fetch(descriptor)
                if existingScores.isEmpty {
                    // Insert new score from cloud
                    let newScore = HighScore(
                        score: remoteScore.score,
                        level: remoteScore.difficultyLevel,
                        questionsAnswered: remoteScore.questionsAnswered,
                        correctAnswers: remoteScore.correctAnswers,
                        date: remoteScore.date
                    )
                    newScore.id = remoteScore.id
                    newScore.cloudRecordID = remoteScore.cloudRecordID
                    modelContext.insert(newScore)
                }
            } catch {
                print("Error merging remote score: \(error)")
            }
        }

        do {
            try modelContext.save()
            refreshScores()
        } catch {
            print("Failed to save merged scores: \(error)")
        }
    }
}
