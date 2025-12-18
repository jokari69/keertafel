import SwiftUI

struct UsernamePromptView: View {
    @ObservedObject var userService: UserService
    @State private var inputName: String = ""
    @FocusState private var isFocused: Bool

    var isValid: Bool {
        inputName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.deepPurple, Color.electricBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Icon
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.gold, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Title
                VStack(spacing: 4) {
                    Text("Welkom bij")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))

                    Text("MIOMONDO")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))

                    Text("MATH BLITZ")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.gold, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // Subtitle
                Text("Vul je naam in om mee te doen aan de wereldranglijst!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Input field
                VStack(spacing: 8) {
                    TextField("", text: $inputName, prompt: Text("Jouw naam").foregroundColor(.white.opacity(0.5)))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                        )
                        .padding(.horizontal, 40)

                    Text("Minimaal 2 tekens")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                // Continue button
                Button {
                    if isValid {
                        userService.setUsername(inputName)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("STARTEN!")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                isValid
                                    ? LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                            )
                            .shadow(color: isValid ? .green.opacity(0.4) : .clear, radius: 10)
                    )
                    .padding(.horizontal, 40)
                }
                .disabled(!isValid)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            inputName = userService.username
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

#Preview {
    UsernamePromptView(userService: UserService())
}
