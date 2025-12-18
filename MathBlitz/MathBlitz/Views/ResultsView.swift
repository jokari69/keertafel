import SwiftUI
import SwiftData

struct ResultsView: View {
    let score: Int
    let questionsAnswered: Int
    let correctAnswers: Int
    let level: DifficultyLevel
    let onPlayAgain: () -> Void
    let onExit: () -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var cloudKitService: CloudKitService
    @EnvironmentObject var userService: UserService
    @StateObject private var highScoreViewModel = HighScoreViewModel()

    @State private var animateScore = false
    @State private var animateStats = false
    @State private var animateButtons = false
    @State private var isNewBestToday = false
    @State private var isNewAllTime = false
    @State private var earnedBadges: [Badge] = []
    @State private var showBadgeAnimation = false

    private var accuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsAnswered) * 100
    }

    var body: some View {
        GeometryReader { geometry in
            let isIPad = geometry.size.width > 600

            ScrollView {
                VStack(spacing: isIPad ? 40 : 24) {
                    // Header
                    headerSection(isIPad: isIPad)

                    // Score Display
                    scoreSection(isIPad: isIPad)

                    // New Record Badges
                    if isNewAllTime || isNewBestToday {
                        newRecordBadge(isIPad: isIPad)
                    }

                    // Stats Grid
                    statsSection(isIPad: isIPad)

                    // Earned Badges
                    if !earnedBadges.isEmpty {
                        badgesSection(isIPad: isIPad)
                    }

                    // Action Buttons
                    buttonsSection(isIPad: isIPad)
                }
                .padding(.horizontal, isIPad ? 60 : 24)
                .padding(.vertical, 40)
            }
        }
        .onAppear {
            setupView()
        }
    }

    private func setupView() {
        highScoreViewModel.setModelContext(modelContext)

        // Check for new records
        isNewBestToday = highScoreViewModel.isNewHighScore(score: score, level: level, isToday: true)
        isNewAllTime = highScoreViewModel.isNewHighScore(score: score, level: level, isToday: false)

        // Calculate earned badges
        calculateEarnedBadges()

        // Save score locally
        highScoreViewModel.saveScoreLocally(
            score: score,
            level: level,
            questionsAnswered: questionsAnswered,
            correctAnswers: correctAnswers
        )

        // Save to CloudKit (global leaderboard)
        Task {
            await cloudKitService.saveScore(
                score,
                level: level,
                questionsAnswered: questionsAnswered,
                correctAnswers: correctAnswers,
                username: userService.username
            )
        }

        // Animate in
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
            animateScore = true
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4)) {
            animateStats = true
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7)) {
            animateButtons = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(1.0)) {
            showBadgeAnimation = true
        }
    }

    private func calculateEarnedBadges() {
        var badges: [Badge] = []

        // First game badge (simplified - always show for demo)
        if score > 0 {
            badges.append(.firstGame)
        }

        // Score milestones
        if score >= 10 { badges.append(.score10) }
        if score >= 20 { badges.append(.score20) }
        if score >= 30 { badges.append(.score30) }

        earnedBadges = badges
    }

    // MARK: - Header Section
    private func headerSection(isIPad: Bool) -> some View {
        VStack(spacing: 8) {
            Text("TIJD IS OP!")
                .font(.system(size: isIPad ? 32 : 24, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            Text(level.displayName)
                .font(.system(size: isIPad ? 20 : 16, weight: .semibold, design: .rounded))
                .foregroundColor(level.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(level.color.opacity(0.2))
                )
        }
    }

    // MARK: - Score Section
    private func scoreSection(isIPad: Bool) -> some View {
        VStack(spacing: 8) {
            Text("JOUW SCORE")
                .font(.system(size: isIPad ? 16 : 14, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)

            Text("\(score)")
                .font(.system(size: isIPad ? 120 : 96, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.gold, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .gold.opacity(0.5), radius: 20)
        }
        .scaleEffect(animateScore ? 1 : 0.3)
        .opacity(animateScore ? 1 : 0)
    }

    // MARK: - New Record Badge
    private func newRecordBadge(isIPad: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundColor(.gold)

            VStack(alignment: .leading, spacing: 2) {
                if isNewAllTime {
                    Text("NIEUW RECORD!")
                        .font(.system(size: isIPad ? 18 : 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                } else {
                    Text("BESTE VAN VANDAAG!")
                        .font(.system(size: isIPad ? 18 : 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundColor(.gold)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.gold.opacity(0.3), .orange.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gold, lineWidth: 2)
                )
        )
        .scaleEffect(animateScore ? 1 : 0.5)
        .opacity(animateScore ? 1 : 0)
    }

    // MARK: - Stats Section
    private func statsSection(isIPad: Bool) -> some View {
        HStack(spacing: isIPad ? 30 : 16) {
            StatBox(
                title: "BEANTWOORD",
                value: "\(questionsAnswered)",
                icon: "questionmark.circle.fill",
                color: .blue,
                isIPad: isIPad
            )

            StatBox(
                title: "GOED",
                value: "\(correctAnswers)",
                icon: "checkmark.circle.fill",
                color: .green,
                isIPad: isIPad
            )

            StatBox(
                title: "SCORE",
                value: String(format: "%.0f%%", accuracy),
                icon: "target",
                color: .orange,
                isIPad: isIPad
            )
        }
        .scaleEffect(animateStats ? 1 : 0.8)
        .opacity(animateStats ? 1 : 0)
    }

    // MARK: - Badges Section
    private func badgesSection(isIPad: Bool) -> some View {
        VStack(spacing: 12) {
            Text("VERDIENDE BADGES")
                .font(.system(size: isIPad ? 14 : 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)

            HStack(spacing: 16) {
                ForEach(earnedBadges, id: \.rawValue) { badge in
                    BadgeView(badge: badge, isIPad: isIPad)
                        .scaleEffect(showBadgeAnimation ? 1 : 0)
                }
            }
        }
    }

    // MARK: - Buttons Section
    private func buttonsSection(isIPad: Bool) -> some View {
        VStack(spacing: 16) {
            Button(action: onPlayAgain) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                    Text("OPNIEUW SPELEN")
                        .font(.system(size: isIPad ? 20 : 18, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, isIPad ? 20 : 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .green.opacity(0.4), radius: 10)
                )
            }

            Button(action: onExit) {
                HStack(spacing: 12) {
                    Image(systemName: "house.fill")
                        .font(.title3)
                    Text("MENU")
                        .font(.system(size: isIPad ? 20 : 18, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, isIPad ? 20 : 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                )
            }
        }
        .scaleEffect(animateButtons ? 1 : 0.8)
        .opacity(animateButtons ? 1 : 0)
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isIPad: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: isIPad ? 28 : 22))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: isIPad ? 28 : 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(title)
                .font(.system(size: isIPad ? 12 : 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isIPad ? 20 : 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Badge View

struct BadgeView: View {
    let badge: Badge
    let isIPad: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(badge.color.opacity(0.2))
                    .frame(width: isIPad ? 60 : 50, height: isIPad ? 60 : 50)

                Image(systemName: badge.icon)
                    .font(.system(size: isIPad ? 28 : 22))
                    .foregroundColor(badge.color)
            }

            Text(badge.rawValue)
                .font(.system(size: isIPad ? 12 : 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.deepPurple, Color.electricBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ResultsView(
            score: 25,
            questionsAnswered: 30,
            correctAnswers: 27,
            level: .upTo12,
            onPlayAgain: {},
            onExit: {}
        )
    }
    .modelContainer(for: HighScore.self, inMemory: true)
    .environmentObject(CloudKitService())
}
