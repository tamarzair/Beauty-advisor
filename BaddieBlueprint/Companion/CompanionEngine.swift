//
//  CompanionEngine.swift
//  Baddie Blueprint
//
//  UI-facing adapter over CompanionMood/RoutineCycle for views that only
//  care about a coarse 3-tier appearance and the current time-of-day cycle.
//

import Foundation
import Combine

enum CompanionAppearanceState {
    case snatched
    case maintenance
    case bummy
}

typealias CompanionTimeState = RoutineCycle

@MainActor
final class CompanionEngine: ObservableObject {
    @Published private(set) var appearanceState: CompanionAppearanceState = .maintenance
    @Published private(set) var timeState: CompanionTimeState = .morning

    func updateState(for log: DailyLog, now: Date = .now) {
        timeState = RoutineCycle.current(for: now)
        appearanceState = Self.appearance(for: log.companionMood)
    }

    private static func appearance(for mood: CompanionMood) -> CompanionAppearanceState {
        switch mood {
        case .snatched:
            return .snatched
        case .glowing, .coasting:
            return .maintenance
        case .tired, .bummy:
            return .bummy
        }
    }
}
