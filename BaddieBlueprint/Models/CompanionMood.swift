//
//  CompanionMood.swift
//  Baddie Blueprint
//

import Foundation

/// The companion's visible mood, driven by today's routine completion rate.
enum CompanionMood: String, Codable, CaseIterable, Sendable {
    case thriving
    case coasting
    case sluggish
    case neglected

    var spriteAssetName: String {
        "companion_\(rawValue)"
    }
}
