import SwiftUI
import SwiftData

struct HomeView: View {
    let onSelectLevel: (DifficultyLevel) -> Void
    let onShowHighScores: () -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var userService: UserService
    @StateObject private var highScoreViewModel = HighScoreViewModel()
    @State private var animateTitle = false
    @State private var animateButtons = false
    @State private var showingChangeUsername = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Username badge
                usernameBadge

                // Title Section
                titleSection

                // Difficulty Selection
                difficultySection

                // High Scores Button
                highScoresButton

                Spacer(minLength: 50)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .sheet(isPresented: $showingChangeUsername) {
            ChangeUsernameSheet(userService: userService)
        }
        .onAppear {
            highScoreViewModel.setModelContext(modelContext)
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                animateTitle = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                animateButtons = true
            }
        }
    }

    // MARK: - Username Badge
    private var usernameBadge: some View {
        Button {
            showingChangeUsername = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.gold)

                Text(userService.username)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(Color.gold.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 4) {
            Text("MIOMONDO")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            Text("MATH BLITZ")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.gold, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .orange.opacity(0.5), radius: 15)

            Text("60 seconden rekengekte!")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 8)
        }
        .scaleEffect(animateTitle ? 1 : 0.5)
        .opacity(animateTitle ? 1 : 0)
    }

    // MARK: - Difficulty Section
    private var difficultySection: some View {
        VStack(spacing: 16) {
            Text("KIES NIVEAU")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .tracking(2)

            ForEach(Array(DifficultyLevel.allCases.enumerated()), id: \.element.id) { index, level in
                DifficultyButton(
                    level: level,
                    bestScore: highScoreViewModel.allTimeScores[level]??.score,
                    onTap: { onSelectLevel(level) }
                )
                .offset(x: animateButtons ? 0 : (index % 2 == 0 ? -200 : 200))
                .opacity(animateButtons ? 1 : 0)
            }
        }
    }

    // MARK: - High Scores Button
    private var highScoresButton: some View {
        Button(action: onShowHighScores) {
            HStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundColor(.gold)

                Text("RANGLIJST")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gold.opacity(0.5), lineWidth: 2)
                    )
            )
        }
        .scaleEffect(animateButtons ? 1 : 0.8)
        .opacity(animateButtons ? 1 : 0)
    }
}

// MARK: - Difficulty Button

struct DifficultyButton: View {
    let level: DifficultyLevel
    let bestScore: Int?
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(level.gradient)
                        .frame(width: 50, height: 50)

                    Image(systemName: level.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }

                // Level Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(level.difficulty)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Best Score
                if let score = bestScore {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("BESTE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))

                        Text("\(score)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.gold)
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(level.color.opacity(0.4), lineWidth: 2)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Change Username Sheet

struct ChangeUsernameSheet: View {
    @ObservedObject var userService: UserService
    @Environment(\.dismiss) private var dismiss
    @State private var newName: String = ""
    @FocusState private var isFocused: Bool

    var isValid: Bool {
        newName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.deepPurple, Color.electricBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gold)

                    Text("Wijzig je naam")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    TextField("", text: $newName, prompt: Text("Nieuwe naam").foregroundColor(.white.opacity(0.5)))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.15))
                        )
                        .padding(.horizontal, 40)

                    Button {
                        if isValid {
                            userService.setUsername(newName)
                            dismiss()
                        }
                    } label: {
                        Text("OPSLAAN")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isValid ? Color.green : Color.gray)
                            )
                            .padding(.horizontal, 40)
                    }
                    .disabled(!isValid)

                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleer") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            newName = userService.username
            isFocused = true
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

        HomeView(
            onSelectLevel: { _ in },
            onShowHighScores: {}
        )
        .environmentObject(UserService())
    }
    .modelContainer(for: HighScore.self, inMemory: true)
}
