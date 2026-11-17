import SwiftUI

/// 加减按钮。
struct StepButton: View {
    var symbol: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.white.opacity(0.08)))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(TapScale())
    }
}

/// 数字步进行。
struct StepperRow: View {
    var title: String
    @Binding var value: Int
    var range: ClosedRange<Int>
    var unit: String = "分钟"

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 14.5, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))

            Spacer()

            HStack(spacing: 12) {
                StepButton(symbol: "minus") {
                    if value > range.lowerBound {
                        value -= 1
                        Haptics.soft()
                    }
                }
                Text("\(value) \(unit)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .frame(minWidth: 62, alignment: .trailing)
                StepButton(symbol: "plus") {
                    if value < range.upperBound {
                        value += 1
                        Haptics.soft()
                    }
                }
            }
        }
    }
}

/// 开关行。
struct ToggleRow: View {
    var title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.42))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Theme.coral)
    }
}

/// 统计小卡。
struct StatTile: View {
    var title: String
    var value: String
    var unit: String
    var symbol: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(tint)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.system(size: 10.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.42))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.055))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
        )
    }
}
