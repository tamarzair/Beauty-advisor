import SwiftUI

enum CompanionTimeState {
    case morning, afternoon, night
}

enum CompanionMood {
    case glowing      // 100% execution
    case thriving     // > 75% execution
    case managing     // 40% - 75% execution
    case struggling   // 15% - 40% execution
    case neglected    // < 15% execution
}

enum CompanionAppearanceState {
    case snatched     // Maps to glowing/thriving
    case maintenance  // Maps to managing
    case bummy        // Maps to struggling/neglected
}

class CompanionEngine: ObservableObject {
    @Published var timeState: CompanionTimeState = .morning
    @Published var currentMood: CompanionMood = .managing
    @Published var appearanceState: CompanionAppearanceState = .maintenance

    func updateState(for log: DailyLog) {
        // 1. Determine Time of Day Cycle
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 5 && hour < 12 {
            timeState = .morning
        } else if hour >= 12 && hour < 18 {
            timeState = .afternoon
        } else {
            timeState = .night
        }

        // 2. Evaluate Dynamic Routine Task Completion Percentage
        let tasks = log.requiredTasks
        guard !tasks.isEmpty else {
            setStates(for: .neglected, completionRate: 0)
            return
        }

        let completedCount = tasks.filter { $0.isCompleted }.count
        let completionRate = Double(completedCount) / Double(tasks.count)

        // 3. Map to 5-Tier Mood
        let calculatedMood: CompanionMood
        switch completionRate {
        case 1.0:
            calculatedMood = .glowing
        case 0.75..<1.0:
            calculatedMood = .thriving
        case 0.40..<0.75:
            calculatedMood = .managing
        case 0.15..<0.40:
            calculatedMood = .struggling
        default:
            calculatedMood = .neglected
        }

        setStates(for: calculatedMood, completionRate: completionRate)
    }

    private func setStates(for mood: CompanionMood, completionRate: Double) {
        self.currentMood = mood
        switch mood {
        case .glowing, .thriving:
            appearanceState = .snatched
        case .managing:
            appearanceState = .maintenance
        case .struggling, .neglected:
            appearanceState = .bummy
        }

        // Sync state to shared container for Widget access
        SharedDefaults.writeWidgetData(
            appearance: String(describing: appearanceState),
            mood: String(describing: currentMood),
            completionRate: completionRate
        )
    }
}
