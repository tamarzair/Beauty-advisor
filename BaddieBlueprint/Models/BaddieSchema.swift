//
//  BaddieSchema.swift
//  Baddie Blueprint
//
//  Single source of truth for the SwiftData schema, shared by the app and
//  the widget extension's ModelContainer configuration.
//

import SwiftData

enum BaddieSchema {
    static let schema = Schema([
        UserProfile.self,
        DailyLog.self,
        RoutineTask.self,
        CompanionState.self,
    ])
}
