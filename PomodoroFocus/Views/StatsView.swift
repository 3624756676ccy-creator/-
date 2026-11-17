import Charts
import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 15) {
                header
                tiles
                chartCard
                rankingCard
                summaryCard
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("专注统计")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("累计 \(model.totalFocusCount) 个番茄")
                    .font(.system(size: 11.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
        }
    }

    private var tiles: some View {
        HStack(spacing: 10) {
            StatTile(
                title: "今日番茄",
                value: "\(model.todayFocusCount)",
                unit: "个",
                symbol: "flame.fill",
                tint: Theme.coral
            )
            StatTile(
                title: "专注时长",
                value: model.todayFocusText,
                unit: model.todayFocusUnit,
                symbol: "clock.fill",
                tint: Theme.amber
            )
            StatTile(
                title: "连续打卡",
                value: "\(model.streakDays)",
                unit: "天",
                symbol: "bolt.fill",
                tint: Theme.mint
            )
        }
    }

    private var chartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("最近 7 天")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("共 \(model.weekSeries().reduce(0) { $0 + $1.count }) 个")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }

                Chart(model.weekSeries()) { item in
                    BarMark(
                        x: .value("日期", item.label),
                        y: .value("番茄数", item.count)
                    )
                    .foregroundStyle(
                        item.count == 0
                            ? AnyShapeStyle(Color.white.opacity(0.10))
                            : AnyShapeStyle(Theme.focusGradient)
                    )
                    .cornerRadius(7)
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.32))
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                }
                .frame(height: 170)
            }
        }
    }

    private var rankingCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("任务排行")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                let ranks = model.taskRanking()
                if ranks.isEmpty {
                    Text("完成任务后，这里会显示每个任务累计的番茄数。")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.white.opacity(0.42))
                } else {
                    let maxCount = max(1, ranks.map { $0.done }.max() ?? 1)
                    VStack(spacing: 12) {
                        ForEach(ranks) { rank in
                            HStack(spacing: 10) {
                                Text(rank.title)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.85))
                                    .lineLimit(1)
                                    .frame(width: 110, alignment: .leading)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.07))
                                        Capsule()
                                            .fill(Theme.focusGradient)
                                            .frame(width: max(6, geo.size.width * CGFloat(rank.done) / CGFloat(maxCount)))
                                    }
                                }
                                .frame(height: 7)

                                Text("\(rank.done)")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(.white.opacity(0.6))
                                    .frame(width: 22, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
    }

    private var summaryCard: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.peach)
                Text(model.weeklySummary)
                    .font(.system(size: 12.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
