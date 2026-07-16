//
//  DashboardView.swift
//  Baddie Blueprint
//
//  Home screen: the companion render area plus today's routine checklist,
//  driven directly by DailyLog/RoutineTask from BaddieBlueprintSchema.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @StateObject private var engine = CompanionEngine()

    private var profile: UserProfile? { profiles.first }

    var currentLog: DailyLog {
        (try? SharedPersistence.todayLog(in: modelContext, profile: profile))
            ?? DailyLog(day: Calendar.current.startOfDay(for: .now))
    }

    var body: some View {
        NavigationStack {
            VQueueView(currentLog: currentLog, engine: engine)
                .navigationTitle("Baddie Blueprint")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    engine.updateState(for: currentLog)
                }
        }
    }
}

// Subview layout to minimize structural body size
struct VQueueView: View {
    var currentLog: DailyLog
    @ObservedObject var engine: CompanionEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Tamagotchi Character Render Area
                VStack {
                    CharacterDisplayView(appearance: engine.appearanceState, time: engine.timeState)
                        .frame(height: 240)
                        .cornerRadius(16)
                        .shadow(radius: 4)

                    Text(statusMessage(for: engine.appearanceState))
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)

                // Routine Actions Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Requirements")
                        .font(.title3)
                        .fontWeight(.bold)

                    ForEach(currentLog.requiredTasks.sorted(by: { $0.sortOrder < $1.sortOrder })) { task in
                        Toggle(task.title, isOn: Bindable(task).isCompleted)
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(16)
                .onChange(of: currentLog.completionRate) { _, _ in
                    engine.updateState(for: currentLog)
                }
            }
            .padding()
        }
    }

    private func statusMessage(for state: CompanionAppearanceState) -> String {
        switch state {
        case .snatched: return "SNATCHED: Face Card Approved."
        case .maintenance: return "MAINTENANCE: Get up, do your hair."
        case .bummy: return "ALERT: Looking tired. Fix it immediately."
        }
    }
}

// Placeholder for rendering custom pixel art / Assets
struct CharacterDisplayView: View {
    var appearance: CompanionAppearanceState
    var time: CompanionTimeState

    var body: some View {
        ZStack {
            Color.black
            VStack {
                Text(pixelPlaceholder(for: appearance))
                    .font(.system(size: 64))
                Text("[Time Cycle: \(String(describing: time).uppercased())]")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private func pixelPlaceholder(for state: CompanionAppearanceState) -> String {
        switch state {
        case .snatched: return "💅💄✨"
        case .maintenance: return "🧴🧖‍♀️✂️"
        case .bummy: return "🛌💀🏚️"
        }
    }
}
