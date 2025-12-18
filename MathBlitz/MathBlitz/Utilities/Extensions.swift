import SwiftUI

// MARK: - Color Extensions

extension Color {
    static let deepPurple = Color(red: 0.4, green: 0.2, blue: 0.8)
    static let electricBlue = Color(red: 0.2, green: 0.4, blue: 0.9)
    static let neonGreen = Color(red: 0.2, green: 0.9, blue: 0.4)
    static let hotPink = Color(red: 1.0, green: 0.2, blue: 0.5)
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let silver = Color(red: 0.75, green: 0.75, blue: 0.75)
    static let bronze = Color(red: 0.8, green: 0.5, blue: 0.2)

    static let correctGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let wrongRed = Color(red: 0.9, green: 0.2, blue: 0.3)

    static let cardBackground = Color.white.opacity(0.15)
    static let cardBackgroundSolid = Color(red: 0.15, green: 0.1, blue: 0.3)
}

// MARK: - View Extensions

extension View {
    func glowEffect(color: Color, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color.opacity(0.8), radius: radius)
            .shadow(color: color.opacity(0.5), radius: radius * 2)
    }

    func cardStyle() -> some View {
        self
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    func bounceEffect(trigger: Bool) -> some View {
        self.scaleEffect(trigger ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: trigger)
    }

    func shakeEffect(trigger: Int) -> some View {
        self.modifier(ShakeModifier(shakes: trigger))
    }
}

struct ShakeModifier: ViewModifier, Animatable {
    var shakes: Int

    var animatableData: CGFloat {
        get { CGFloat(shakes) }
        set { shakes = Int(newValue) }
    }

    func body(content: Content) -> some View {
        content
            .offset(x: sin(CGFloat(shakes) * .pi * 2) * 10)
    }
}

// MARK: - Font Extensions

extension Font {
    static func gameTitle() -> Font {
        .system(size: 48, weight: .black, design: .rounded)
    }

    static func scoreDisplay() -> Font {
        .system(size: 64, weight: .bold, design: .rounded)
    }

    static func questionText() -> Font {
        .system(size: 56, weight: .bold, design: .rounded)
    }

    static func answerText() -> Font {
        .system(size: 32, weight: .semibold, design: .rounded)
    }

    static func timerText() -> Font {
        .system(size: 28, weight: .bold, design: .monospaced)
    }

    static func buttonText() -> Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }
}

// MARK: - Date Extensions

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    func formatted(as format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

// MARK: - Number Formatting

extension Int {
    var formattedScore: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Double {
    var percentageString: String {
        String(format: "%.0f%%", self)
    }
}
