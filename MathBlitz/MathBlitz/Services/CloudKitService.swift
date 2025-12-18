import Foundation
import CloudKit
import SwiftData
import Combine

@MainActor
class CloudKitService: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var globalLeaderboard: [LeaderboardEntry] = []

    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let recordType = "HighScore"

    init() {
        container = CKContainer(identifier: "iCloud.com.jvdm.mathblitz.app")
        publicDatabase = container.publicCloudDatabase
    }

    func syncScores() {
        Task {
            await performSync()
        }
    }

    private func performSync() async {
        guard !isSyncing else { return }

        isSyncing = true
        syncError = nil

        do {
            // Fetch global leaderboard
            await fetchGlobalLeaderboard()
            lastSyncDate = Date()
            isSyncing = false
        } catch {
            syncError = error.localizedDescription
            isSyncing = false
        }
    }

    func fetchGlobalLeaderboard() async {
        do {
            var allEntries: [LeaderboardEntry] = []

            for level in DifficultyLevel.allCases {
                let entries = try await fetchTopScores(for: level, limit: 10)
                allEntries.append(contentsOf: entries)
            }

            globalLeaderboard = allEntries
        } catch {
            print("Failed to fetch leaderboard: \(error)")
        }
    }

    func fetchTopScores(for level: DifficultyLevel, limit: Int = 10) async throws -> [LeaderboardEntry] {
        let predicate = NSPredicate(format: "level == %@", level.rawValue)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "score", ascending: false)]

        let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: limit)
        var entries: [LeaderboardEntry] = []

        for (_, result) in results {
            if case .success(let record) = result,
               let entry = LeaderboardEntry.fromCKRecord(record) {
                entries.append(entry)
            }
        }

        return entries.sorted { $0.score > $1.score }
    }

    func saveScore(_ score: Int, level: DifficultyLevel, questionsAnswered: Int, correctAnswers: Int, username: String) async {
        guard !username.isEmpty else {
            print("Cannot save score without username")
            return
        }

        do {
            let record = CKRecord(recordType: recordType)
            record["score"] = score as CKRecordValue
            record["level"] = level.rawValue as CKRecordValue
            record["date"] = Date() as CKRecordValue
            record["questionsAnswered"] = questionsAnswered as CKRecordValue
            record["correctAnswers"] = correctAnswers as CKRecordValue
            record["username"] = username as CKRecordValue

            _ = try await publicDatabase.save(record)

            // Refresh leaderboard after saving
            await fetchGlobalLeaderboard()
        } catch {
            print("Failed to save score to CloudKit: \(error)")
        }
    }
}

// Leaderboard entry for display
struct LeaderboardEntry: Identifiable {
    let id: String
    let username: String
    let score: Int
    let level: DifficultyLevel
    let date: Date
    let questionsAnswered: Int
    let correctAnswers: Int

    var accuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsAnswered) * 100
    }

    static func fromCKRecord(_ record: CKRecord) -> LeaderboardEntry? {
        guard let username = record["username"] as? String,
              let score = record["score"] as? Int,
              let levelString = record["level"] as? String,
              let level = DifficultyLevel(rawValue: levelString),
              let date = record["date"] as? Date else {
            return nil
        }

        let questionsAnswered = record["questionsAnswered"] as? Int ?? 0
        let correctAnswers = record["correctAnswers"] as? Int ?? 0

        return LeaderboardEntry(
            id: record.recordID.recordName,
            username: username,
            score: score,
            level: level,
            date: date,
            questionsAnswered: questionsAnswered,
            correctAnswers: correctAnswers
        )
    }
}

extension Notification.Name {
    static let cloudKitScoresFetched = Notification.Name("cloudKitScoresFetched")
}
