import Foundation
import SwiftData

@Model
final class MaintenanceCycle {
    var id: UUID
    var name: String
    var frequencyDays: Int
    var lastCompletedDate: Date

    var nextDueDate: Date {
        Calendar.current.date(byAdding: .day, value: frequencyDays, to: lastCompletedDate) ?? lastCompletedDate
    }

    var isOverdue: Bool {
        Date() > nextDueDate
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: nextDueDate)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }

    init(id: UUID = UUID(), name: String, frequencyDays: Int, lastCompletedDate: Date = Date()) {
        self.id = id
        self.name = name
        self.frequencyDays = frequencyDays
        self.lastCompletedDate = lastCompletedDate
    }
}
