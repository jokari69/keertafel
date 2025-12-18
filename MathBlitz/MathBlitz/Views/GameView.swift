import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    var onAbandon: (() -> Void)?
    @State private var confettiCounter = 0

    var body: some View {
        GeometryReader { geometry in
            let isIPad = geometry.size.width > 600

            VStack(spacing: isIPad ? 40 : 24) {
                // Top Bar: Timer and Score
                topBar(isIPad: isIPad)

                Spacer()

                if viewModel.gameState == .ready {
                    readyView(isIPad: isIPad)
                } else {
                    // Question Display
                    questionView(isIPad: isIPad)

                    Spacer()

                    // Answer Buttons
                    answerGrid(isIPad: isIPad, screenWidth: geometry.size.width)
                }

                Spacer()
            }
            .padding(.horizontal, isIPad ? 60 : 24)
            .padding(.vertical, 20)
        }
        .overlay(
            ConfettiView(counter: $confettiCounter)
        )
        .onChange(of: viewModel.showCorrectAnimation) { _, newValue in
            if newValue {
                confettiCounter += 1
            }
        }
    }

    // MARK: - Top Bar
    private func topBar(isIPad: Bool) -> some View {
        HStack(spacing: 12) {
            // Timer
            timerView(isIPad: isIPad)
                .fixedSize()

            Spacer()

            // Streak indicator
            if viewModel.currentStreak >= 3 {
                streakBadge(isIPad: isIPad)
                    .fixedSize()
            }

            // Score
            scoreView(isIPad: isIPad)
                .fixedSize()
        }
    }

    private func timerView(isIPad: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: isIPad ? 24 : 18))
                .foregroundColor(viewModel.isTimeLow ? .red : .white)

            Text(viewModel.formattedTime)
                .font(.system(size: isIPad ? 32 : 24, weight: .bold, design: .monospaced))
                .foregroundColor(viewModel.isTimeLow ? .red : .white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(viewModel.isTimeLow ? Color.red.opacity(0.3) : Color.white.opacity(0.15))
        )
        .scaleEffect(viewModel.isTimeLow && Int(viewModel.timeRemaining) % 2 == 0 ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.5), value: viewModel.isTimeLow)
    }

    private func streakBadge(isIPad: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            Text("\(viewModel.currentStreak)")
                .font(.system(size: isIPad ? 20 : 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .opacity(0.8)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }

    private func scoreView(isIPad: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: isIPad ? 24 : 18))
                .foregroundColor(.gold)

            Text("\(viewModel.score)")
                .font(.system(size: isIPad ? 36 : 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.15))
        )
        .bounceEffect(trigger: viewModel.showCorrectAnimation)
    }

    // MARK: - Ready View
    private func readyView(isIPad: Bool) -> some View {
        VStack(spacing: 30) {
            Text("Klaar?")
                .font(.system(size: isIPad ? 64 : 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Je hebt 60 seconden om zoveel mogelijk keersommen op te lossen!")
                .font(.system(size: isIPad ? 20 : 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button(action: viewModel.startGame) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text("START")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 50)
                .padding(.vertical, 20)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .green.opacity(0.5), radius: 15)
                )
            }

            if let onAbandon = onAbandon {
                Button(action: onAbandon) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Terug")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    // MARK: - Question View
    private func questionView(isIPad: Bool) -> some View {
        VStack(spacing: 16) {
            Text(viewModel.currentQuestion.questionText)
                .font(.system(size: isIPad ? 96 : 64, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 5)
                .shakeEffect(trigger: viewModel.shakeCount)

            Text("= ?")
                .font(.system(size: isIPad ? 56 : 40, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, isIPad ? 40 : 20)
    }

    // MARK: - Answer Grid
    private func answerGrid(isIPad: Bool, screenWidth: CGFloat) -> some View {
        let columns = isIPad ? 4 : 2
        let spacing: CGFloat = isIPad ? 20 : 12

        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            ForEach(0..<viewModel.currentQuestion.choices.count, id: \.self) { index in
                AnswerButton(
                    answer: viewModel.currentQuestion.choices[index],
                    index: index,
                    isSelected: viewModel.selectedAnswerIndex == index,
                    isCorrect: viewModel.currentQuestion.correctAnswerIndex == index,
                    showResult: viewModel.selectedAnswerIndex != nil,
                    isIPad: isIPad,
                    onTap: {
                        viewModel.submitAnswer(choiceIndex: index)
                    }
                )
            }
        }
        .padding(.bottom, isIPad ? 40 : 20)
    }
}

// MARK: - Answer Button

struct AnswerButton: View {
    let answer: Int
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool
    let showResult: Bool
    let isIPad: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    private var backgroundColor: Color {
        if showResult {
            if isSelected {
                return isCorrect ? .correctGreen : .wrongRed
            } else if isCorrect {
                return .correctGreen.opacity(0.5)
            }
        }
        return Color.white.opacity(0.15)
    }

    private var borderColor: Color {
        if showResult {
            if isSelected || isCorrect {
                return isCorrect ? .correctGreen : .wrongRed
            }
        }
        return Color.white.opacity(0.3)
    }

    var body: some View {
        Button(action: onTap) {
            Text("\(answer)")
                .font(.system(size: isIPad ? 48 : 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 100 : 80)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(borderColor, lineWidth: 3)
                        )
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .scaleEffect(isSelected && showResult ? (isCorrect ? 1.05 : 0.95) : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(showResult)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            if !showResult {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }
        }, perform: {})
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showResult)
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @Binding var counter: Int
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: counter) { _, _ in
            spawnConfetti()
        }
    }

    private func spawnConfetti() {
        let colors: [Color] = [.gold, .orange, .yellow, .green, .cyan, .pink]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for _ in 0..<20 {
            let particle = ConfettiParticle(
                id: UUID(),
                position: CGPoint(x: screenWidth / 2, y: screenHeight / 2),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                opacity: 1.0
            )
            particles.append(particle)

            // Animate particle
            let targetX = CGFloat.random(in: 0...screenWidth)
            let targetY = CGFloat.random(in: 0...screenHeight)

            withAnimation(.easeOut(duration: 1.0)) {
                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                    particles[index].position = CGPoint(x: targetX, y: targetY)
                    particles[index].opacity = 0
                }
            }

            // Remove particle after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                particles.removeAll { $0.id == particle.id }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.deepPurple, Color.electricBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        GameView(viewModel: GameViewModel(level: .upTo10))
    }
}
