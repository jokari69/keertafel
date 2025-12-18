import SwiftUI
import SwiftData

struct HighScoresView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var cloudKitService: CloudKitService
    @EnvironmentObject var userService: UserService
    @StateObject private var viewModel = HighScoreViewModel()

    @State private var selectedLevel: DifficultyLevel = .upTo10
    @State private var showingLocalScores = false
    @State private var animateContent = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.deepPurple, Color.electricBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Level Tabs
                    levelTabs

                    // Toggle
                    scopeToggle

                    // Scores Content
                    if showingLocalScores {
                        localScoresContent
                    } else {
                        globalScoresContent
                    }
                }
            }
            .navigationTitle("Ranglijst")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sluit") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if cloudKitService.isSyncing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Button {
                            cloudKitService.syncScores()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            cloudKitService.syncScores()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                animateContent = true
            }
        }
    }

    // MARK: - Level Tabs
    private var levelTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DifficultyLevel.allCases) { level in
                    LevelTab(
                        level: level,
                        isSelected: selectedLevel == level,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedLevel = level
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.black.opacity(0.2))
    }

    // MARK: - Scope Toggle
    private var scopeToggle: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation { showingLocalScores = false }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                    Text("Wereld")
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(showingLocalScores ? .white.opacity(0.6) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(showingLocalScores ? Color.clear : Color.white.opacity(0.2))
                )
            }

            Button {
                withAnimation { showingLocalScores = true }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                    Text("Mijn Scores")
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(showingLocalScores ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(showingLocalScores ? Color.white.opacity(0.2) : Color.clear)
                )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Global Scores Content
    private var globalScoresContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                let levelScores = cloudKitService.globalLeaderboard.filter { $0.level == selectedLevel }

                if levelScores.isEmpty {
                    emptyGlobalView
                } else {
                    ForEach(Array(levelScores.prefix(20).enumerated()), id: \.element.id) { index, entry in
                        GlobalScoreRow(
                            rank: index + 1,
                            entry: entry,
                            isCurrentUser: entry.username == userService.username
                        )
                    }
                }

                if let lastSync = cloudKitService.lastSyncDate {
                    Text("Laatst bijgewerkt: \(lastSync.formatted(as: "d MMM, HH:mm"))")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
    }

    // MARK: - Local Scores Content
    private var localScoresContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Best Scores Section
                bestScoresSection

                // Recent Scores
                recentScoresSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
    }

    // MARK: - Best Scores Section
    private var bestScoresSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "JOUW BESTE", icon: "trophy.fill")

            HStack(spacing: 16) {
                BestScoreCard(
                    title: "VANDAAG",
                    score: viewModel.todayScores[selectedLevel]??.score,
                    icon: "sun.max.fill",
                    color: .orange
                )

                BestScoreCard(
                    title: "ALTIJD",
                    score: viewModel.allTimeScores[selectedLevel]??.score,
                    icon: "crown.fill",
                    color: .gold
                )
            }
        }
    }

    // MARK: - Recent Scores Section
    private var recentScoresSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "RECENTE SPELLEN", icon: "clock.fill")

            let levelScores = viewModel.getScoresForLevel(selectedLevel)

            if levelScores.isEmpty {
                EmptyScoresView(level: selectedLevel)
            } else {
                ForEach(Array(levelScores.prefix(10).enumerated()), id: \.element.id) { index, score in
                    LocalScoreRow(
                        rank: index + 1,
                        score: score,
                        isTopScore: index == 0
                    )
                }
            }
        }
    }

    // MARK: - Empty Global View
    private var emptyGlobalView: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))

            Text("Nog geen wereldscores")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            Text("Wees de eerste met een record op \(selectedLevel.displayName)!")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Global Score Row

struct GlobalScoreRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                if rank <= 3 {
                    Image(systemName: rank == 1 ? "crown.fill" : "\(rank).circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(rankColor)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(rankColor)
                }
            }

            // Username & Score
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.username)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if isCurrentUser {
                        Text("JIJ")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.gold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.gold.opacity(0.2))
                            )
                    }
                }

                Text(entry.date.formatted(as: "MMM d, yyyy"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.score)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(isCurrentUser ? .gold : .white)

                Text(entry.accuracy.percentageString)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isCurrentUser ? 0.15 : 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isCurrentUser ? Color.gold.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .gold
        case 2: return .silver
        case 3: return .bronze
        default: return .white.opacity(0.6)
        }
    }
}

// MARK: - Local Score Row

struct LocalScoreRow: View {
    let rank: Int
    let score: HighScore
    let isTopScore: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                if isTopScore {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gold)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(rankColor)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(score.score) punten")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(score.date.formatted(as: "MMM d, yyyy"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(score.accuracy.percentageString)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))

                Text("\(score.correctAnswers)/\(score.questionsAnswered)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isTopScore ? 0.15 : 0.08))
        )
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .gold
        case 2: return .silver
        case 3: return .bronze
        default: return .white.opacity(0.6)
        }
    }
}

// MARK: - Supporting Views

struct LevelTab: View {
    let level: DifficultyLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: level.icon)
                    .font(.system(size: 14))

                Text(level.shortName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? level.color : Color.white.opacity(0.1))
            )
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.gold)

            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .tracking(2)

            Spacer()
        }
    }
}

struct BestScoreCard: View {
    let title: String
    let score: Int?
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)

            if let score = score {
                Text("\(score)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            } else {
                Text("-")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }

            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

struct EmptyScoresView: View {
    let level: DifficultyLevel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))

            Text("Nog geen scores")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            Text("Speel een spel op \(level.displayName) om je scores hier te zien!")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    HighScoresView()
        .modelContainer(for: HighScore.self, inMemory: true)
        .environmentObject(CloudKitService())
        .environmentObject(UserService())
}
