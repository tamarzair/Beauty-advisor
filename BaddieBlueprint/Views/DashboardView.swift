import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var engine = CompanionEngine()

    var body: some View {
        let currentLog = SharedPersistence.todayLog(in: modelContext)

        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Character Display Box
                    VStack {
                        PixelCharacterView(appearance: engine.appearanceState, time: engine.timeState)
                            .frame(height: 220)
                            .cornerRadius(12)

                        Text("Mood: \(String(describing: engine.currentMood).uppercased())")
                            .font(.system(.subheadline, design: .monospaced))
                            .bold()
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Dynamic Routine Checklist Grouped by Category
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Blueprint Tasks")
                            .font(.title2)
                            .bold()

                        ForEach(currentLog.requiredTasks) { task in
                            TaskRow(task: task) {
                                engine.updateState(for: currentLog)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle("Baddie Blueprint")
            .onAppear {
                engine.updateState(for: currentLog)
            }
        }
    }
}

struct TaskRow: View {
    @Bindable var task: RoutineTask
    var onToggle: () -> Void

    var body: some View {
        Toggle(isOn: $task.isCompleted) {
            VStack(alignment: .leading) {
                Text(task.name)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                Text(task.category.uppercased())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .pink))
        .onChange(of: task.isCompleted) { _, _ in
            onToggle()
        }
    }
}

struct PixelCharacterView: View {
    var appearance: CompanionAppearanceState
    var time: CompanionTimeState

    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 8) {
                Text(characterArt(for: appearance))
                    .font(.system(size: 80))
                Text("Appearance: \(String(describing: appearance).uppercased())")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
    }

    private func characterArt(for state: CompanionAppearanceState) -> String {
        switch state {
        case .snatched: return "💅✨🕶️"
        case .maintenance: return "🧖‍♀️🧴💄"
        case .bummy: return "🛌💀🏚️"
        }
    }
}
