import Foundation
import SwiftData
import CloudKit

@Model
final class HighScore {
    var id: UUID = UUID()
    var score: Int = 0
    var level: String = "10"
    var date: Date = Date()
    var questionsAnswered: Int = 0
    var correctAnswers: Int = 0
    var cloudRecordID: String?

    init(
        score: Int,
        level: DifficultyLevel,
        questionsAnswered: Int,
        correctAnswers: Int,
        date: Date = Date()
    ) {
        self.id = UUID()
        self.score = score
        self.level = level.rawValue
        self.questionsAnswered = questionsAnswered
        self.correctAnswers = correctAnswers
        self.date = date
        self.cloudRecordID = nil
    }

    var difficultyLevel: DifficultyLevel {
        DifficultyLevel(rawValue: level) ?? .upTo10
    }

    var accuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsAnswered) * 100
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    func toCKRecord() -> CKRecord {
        let record: CKRecord
        if let recordID = cloudRecordID {
            record = CKRecord(recordType: "HighScore", recordID: CKRecord.ID(recordName: recordID))
        } else {
            record = CKRecord(recordType: "HighScore")
        }
        record["score"] = score as CKRecordValue
        record["level"] = level as CKRecordValue
        record["date"] = date as CKRecordValue
        record["questionsAnswered"] = questionsAnswered as CKRecordValue
        record["correctAnswers"] = correctAnswers as CKRecordValue
        record["localID"] = id.uuidString as CKRecordValue
        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> HighScore? {
        guard let score = record["score"] as? Int,
              let levelString = record["level"] as? String,
              let level = DifficultyLevel(rawValue: levelString),
              let date = record["date"] as? Date,
              let questionsAnswered = record["questionsAnswered"] as? Int,
              let correctAnswers = record["correctAnswers"] as? Int else {
            return nil
        }

        let highScore = HighScore(
            score: score,
            level: level,
            questionsAnswered: questionsAnswered,
            correctAnswers: correctAnswers,
            date: date
        )
        highScore.cloudRecordID = record.recordID.recordName
        if let localID = record["localID"] as? String, let uuid = UUID(uuidString: localID) {
            highScore.id = uuid
        }
        return highScore
    }
}
