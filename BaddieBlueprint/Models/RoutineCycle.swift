//
//  RoutineCycle.swift
//  Baddie Blueprint
//

import Foundation

/// The two halves of a day's beauty routine.
enum RoutineCycle: String, Codable, CaseIterable, Sendable {
    case morning
    case evening

    /// Which cycle "now" belongs to, splitting the day at 3pm.
    static func current(for date: Date = .now) -> RoutineCycle {
        let hour = Calendar.current.component(.hour, from: date)
        return hour < 15 ? .morning : .evening
    }
}
