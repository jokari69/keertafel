import SwiftUI

struct ContentView: View {
    @State private var selectedLevel: DifficultyLevel?
    @State private var showingHighScores = false
    @StateObject private var cloudKitService = CloudKitService()
    @StateObject private var userService = UserService.shared

    var body: some View {
        Group {
            if userService.showingUsernamePrompt || !userService.hasUsername {
                UsernamePromptView(userService: userService)
            } else {
                mainContent
            }
        }
        .environmentObject(cloudKitService)
        .environmentObject(userService)
    }

    private var mainContent: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.deepPurple, Color.electricBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    if let level = selectedLevel {
                        GameContainerView(
                            level: level,
                            onExit: { selectedLevel = nil },
                            cloudKitService: cloudKitService,
                            userService: userService
                        )
                    } else {
                        HomeView(
                            onSelectLevel: { level in
                                selectedLevel = level
                            },
                            onShowHighScores: {
                                showingHighScores = true
                            }
                        )
                    }
                }
            }
            .sheet(isPresented: $showingHighScores) {
                HighScoresView()
            }
        }
        .onAppear {
            cloudKitService.syncScores()
        }
    }
}

struct GameContainerView: View {
    let level: DifficultyLevel
    let onExit: () -> Void
    @ObservedObject var cloudKitService: CloudKitService
    @ObservedObject var userService: UserService
    @StateObject private var gameViewModel: GameViewModel
    @State private var showResults = false

    init(level: DifficultyLevel, onExit: @escaping () -> Void, cloudKitService: CloudKitService, userService: UserService) {
        self.level = level
        self.onExit = onExit
        self.cloudKitService = cloudKitService
        self.userService = userService
        _gameViewModel = StateObject(wrappedValue: GameViewModel(level: level))
    }

    var body: some View {
        Group {
            if showResults {
                ResultsView(
                    score: gameViewModel.score,
                    questionsAnswered: gameViewModel.questionsAnswered,
                    correctAnswers: gameViewModel.correctAnswers,
                    level: level,
                    onPlayAgain: {
                        showResults = false
                        gameViewModel.resetGame()
                    },
                    onExit: onExit
                )
            } else {
                GameView(viewModel: gameViewModel, onAbandon: onExit)
                    .onChange(of: gameViewModel.gameState) { oldValue, newValue in
                        if newValue == .finished {
                            showResults = true
                        }
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: HighScore.self, inMemory: true)
}
