//
//  SharedPersistence.swift
//  Baddie Blueprint
//
//  App Group–backed SwiftData container shared by the main app and the
//  WidgetKit extension, plus a lightweight snapshot bridge so widget
//  timelines can render instantly without opening the full store.
//

import Foundation
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - App Group configuration

enum AppGroup {
    /// ⚠️ Must match the App Group capability on BOTH targets.
    static let identifier = "group.com.yourcompany.baddieblueprint"

    static var containerURL: URL {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            fatalError("App Group \(identifier) is not configured on this target.")
        }
        return url
    }

    static var storeURL: URL {
        containerURL.appendingPathComponent("BaddieBlueprint.store")
    }

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}

// MARK: - Shared ModelContainer

enum SharedPersistence {
    /// One container definition for app + widget. Local-only: CloudKit is
    /// explicitly disabled so beauty/health data never leaves the device.
    static let container: ModelContainer = {
        let configuration = ModelConfiguration(
            "BaddieBlueprint",
            schema: BaddieSchema.schema,
            url: AppGroup.storeURL,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: BaddieSchema.schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create shared ModelContainer: \(error)")
        }
    }()

    /// Fetch-or-create helpers used by both targets.

    @MainActor
    static func todayLog(in context: ModelContext, profile: UserProfile?) throws -> DailyLog {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let predicate = #Predicate<DailyLog> { $0.day == startOfDay }
        if let existing = try context.fetch(FetchDescriptor(predicate: predicate)).first {
            return existing
        }
        let log = DailyLog(day: startOfDay)
        let gymDay = (profile?.gymDaysPerWeek ?? 0) > 0   // refine with weekday scheduling later
        DailyLog.seedTasks(into: log, gymDayToday: gymDay)
        context.insert(log)
        try context.save()
        return log
    }

    @MainActor
    static func companionState(in context: ModelContext) throws -> CompanionState {
        let wellKnown = CompanionState.wellKnownID
        let predicate = #Predicate<CompanionState> { $0.id == wellKnown }
        if let existing = try context.fetch(FetchDescriptor(predicate: predicate)).first {
            return existing
        }
        let state = CompanionState()
        context.insert(state)
        try context.save()
        return state
    }
}

// MARK: - Widget Snapshot Bridge
//
// Widgets read a tiny pre-computed snapshot from shared UserDefaults for
// instant timeline entries; the full SwiftData store stays the source of
// truth. The app writes this after every mutation and pokes WidgetCenter.

struct CompanionWidgetSnapshot: Codable, Sendable {
    var moodRaw: String
    var spriteAssetName: String
    var streakDays: Int
    var completionRate: Double
    var cycleRaw: String
    var pendingTaskTitles: [String]      // top quick-action toggles, max 4
    var pendingTaskIDs: [UUID]
    var generatedAt: Date

    var mood: CompanionMood { CompanionMood(rawValue: moodRaw) ?? .coasting }
    var cycle: RoutineCycle { RoutineCycle(rawValue: cycleRaw) ?? .morning }
}

enum WidgetBridge {
    private static let snapshotKey = "companionWidgetSnapshot.v1"

    /// Call after any task toggle, hydration update, or companion evaluation.
    @MainActor
    static func publish(dailyLog: DailyLog, companion: CompanionState, now: Date = .now) {
        companion.refreshMood(from: dailyLog)

        let cycle = RoutineCycle.current(for: now)
        let pending = dailyLog.requiredTasks
            .filter { !$0.isCompleted && $0.cycle == cycle }
            .sorted { $0.sortOrder < $1.sortOrder }
            .prefix(4)

        let snapshot = CompanionWidgetSnapshot(
            moodRaw: companion.currentMood.rawValue,
            spriteAssetName: companion.spriteAssetName,
            streakDays: companion.streakDays,
            completionRate: dailyLog.completionRate,
            cycleRaw: cycle.rawValue,
            pendingTaskTitles: pending.map(\.title),
            pendingTaskIDs: pending.map(\.id),
            generatedAt: now
        )

        if let data = try? JSONEncoder().encode(snapshot) {
            AppGroup.sharedDefaults.set(data, forKey: snapshotKey)
        }

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    static func loadSnapshot() -> CompanionWidgetSnapshot? {
        guard let data = AppGroup.sharedDefaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(CompanionWidgetSnapshot.self, from: data)
    }
}
