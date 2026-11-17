import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showEditor = false

    private var openTasks: [FocusTask] {
        model.tasks.filter { !$0.isCompleted }
    }

    private var finishedTasks: [FocusTask] {
        model.tasks.filter { $0.isCompleted }
    }

    var body: some View {
        VStack(spacing: 12) {
            header
                .padding(.horizontal, 22)
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 11) {
                    if model.tasks.isEmpty {
                        emptyState
                    } else {
                        ForEach(openTasks) { task in
                            row(for: task)
                        }

                        if !finishedTasks.isEmpty {
                            SectionTitle(title: "已完成")
                                .padding(.top, 12)
                            ForEach(finishedTasks) { task in
                                row(for: task)
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
            }
        }
        .sheet(isPresented: $showEditor) {
            TaskEditorView()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("任务清单")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("点一下卡片设为当前专注任务")
                    .font(.system(size: 11.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            Button {
                showEditor = true
                Haptics.soft()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.coral.opacity(0.22)))
                    .overlay(Circle().strokeBorder(Theme.coral.opacity(0.45), lineWidth: 1))
            }
            .buttonStyle(TapScale())
        }
    }

    private func row(for task: FocusTask) -> some View {
        TaskRow(
            task: task,
            isActive: model.activeTaskID == task.id,
            onToggle: { model.toggleCompleted(task) },
            onActivate: { model.setActiveTask(task) },
            onDelete: { model.deleteTask(task) }
        )
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checklist")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.white.opacity(0.22))
            Text("还没有任务")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
            Text("先写下一件想完成的事，再开始番茄钟")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
            PrimaryButton(
                title: "新建任务",
                systemImage: "plus",
                gradient: Theme.focusGradient
            ) {
                showEditor = true
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
    }
}

// MARK: - 行

struct TaskRow: View {
    let task: FocusTask
    let isActive: Bool
    var onToggle: () -> Void
    var onActivate: () -> Void
    var onDelete: () -> Void

    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(task.isCompleted ? Theme.mint : Color.white.opacity(0.26))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(task.isCompleted ? Color.white.opacity(0.38) : Color.white)
                        .strikethrough(task.isCompleted, color: Color.white.opacity(0.3))
                        .lineLimit(1)

                    HStack(spacing: 9) {
                        Text("🍅 \(task.done)/\(task.estimate)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))

                        ProgressDots(progress: task.progress)

                        if isActive && !task.isCompleted {
                            Text("当前")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.coral)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(Capsule().fill(Theme.coral.opacity(0.16)))
                        }
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(isActive ? Theme.coral.opacity(0.42) : Color.clear, lineWidth: 1.2)
        )
        .contentShape(Rectangle())
        .onTapGesture { onActivate() }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("删除任务", systemImage: "trash")
            }
        }
    }
}

struct ProgressDots: View {
    var progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.10))
                Capsule()
                    .fill(Theme.focusGradient)
                    .frame(width: max(2, geo.size.width * max(0.02, min(1, progress))))
            }
        }
        .frame(width: 54, height: 4)
    }
}

// MARK: - 新建任务

struct TaskEditorView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var estimate = 4

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 16) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "任务名称")
                            TextField("例如：写完项目方案", text: $title)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                                .textInputAutocapitalization(.never)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                )
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionTitle(title: "预计番茄数")
                            HStack {
                                Text("\(estimate) 个 · 约 \(estimate * max(1, model.settings.focusMinutes)) 分钟")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                                Spacer()
                                HStack(spacing: 16) {
                                    StepButton(symbol: "minus") {
                                        estimate = max(1, estimate - 1)
                                        Haptics.soft()
                                    }
                                    StepButton(symbol: "plus") {
                                        estimate = min(20, estimate + 1)
                                        Haptics.soft()
                                    }
                                }
                            }
                        }
                    }

                    Spacer()

                    PrimaryButton(
                        title: "添加任务",
                        systemImage: "checkmark",
                        gradient: Theme.focusGradient
                    ) {
                        model.addTask(title: title, estimate: estimate)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
            }
            .navigationTitle("新建任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .font(.system(size: 15, design: .rounded))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
