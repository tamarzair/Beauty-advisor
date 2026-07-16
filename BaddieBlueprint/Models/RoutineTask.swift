//
//  RoutineTask.swift
//  Baddie Blueprint
//

import Foundation
import SwiftData

@Model
final class RoutineTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var cycle: RoutineCycle
    var sortOrder: Int
    var isCompleted: Bool

    var dailyLog: DailyLog?

    init(
        id: UUID = UUID(),
        title: String,
        cycle: RoutineCycle,
        sortOrder: Int,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.cycle = cycle
        self.sortOrder = sortOrder
        self.isCompleted = isCompleted
    }
}
