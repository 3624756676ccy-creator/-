import SwiftUI

// MARK: - 调色板

enum Theme {
    static let backgroundTop = Color(hex: 0x140E1B)
    static let backgroundMid = Color(hex: 0x1E1024)
    static let backgroundBottom = Color(hex: 0x2E1220)

    static let coral = Color(hex: 0xFF5E6C)
    static let peach = Color(hex: 0xFFB199)
    static let mint = Color(hex: 0x4ADE9B)
    static let teal = Color(hex: 0x2DD4BF)
    static let amber = Color(hex: 0xFFC46B)

    static let focusGradient = LinearGradient(
        colors: [coral, peach],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let breakGradient = LinearGradient(
        colors: [mint, teal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func accent(for phase: Phase) -> LinearGradient {
        phase == .focus ? focusGradient : breakGradient
    }

    static func tint(for phase: Phase) -> Color {
        phase == .focus ? coral : mint
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - 背景

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.backgroundTop, Theme.backgroundMid, Theme.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Theme.coral.opacity(0.22), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.12),
                startRadius: 4,
                endRadius: 420
            )

            RadialGradient(
                colors: [Theme.teal.opacity(0.10), Color.clear],
                center: UnitPoint(x: 0.15, y: 0.92),
                startRadius: 4,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - 卡片

struct GlassCard<Content: View>: View {
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    private let content: Content

    init(cornerRadius: CGFloat = 26, padding: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.085), Color.white.opacity(0.035)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

// MARK: - 交互反馈

struct TapScale: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - 基础组件

struct CircleIconButton: View {
    var symbol: String
    var size: CGFloat = 56
    var tint: Color = .white
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.34, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(
                    Circle().fill(Color.white.opacity(0.07))
                )
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        }
        .buttonStyle(TapScale())
    }
}

struct ChipView: View {
    var title: String
    var symbol: String?
    var isOn: Bool

    var body: some View {
        HStack(spacing: 6) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
            }
            Text(title).font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(isOn ? Color.white : Color.white.opacity(0.62))
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule().fill(isOn ? Theme.coral.opacity(0.28) : Color.white.opacity(0.06))
        )
        .overlay(
            Capsule().strokeBorder(isOn ? Theme.coral.opacity(0.55) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct SectionTitle: View {
    var title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(1.8)
            .foregroundStyle(.white.opacity(0.38))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PrimaryButton: View {
    var title: String
    var systemImage: String
    var gradient: LinearGradient
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(gradient, in: Capsule())
        }
        .buttonStyle(TapScale())
    }
}

struct ToastView: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(Color(hex: 0x2A1A28).opacity(0.96))
            )
            .overlay(
                Capsule().strokeBorder(Theme.coral.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 18, y: 8)
    }
}
