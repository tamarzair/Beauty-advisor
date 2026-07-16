//
//  UserProfile.swift
//  Baddie Blueprint
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var gymDaysPerWeek: Int?

    init(name: String = "", gymDaysPerWeek: Int? = nil) {
        self.name = name
        self.gymDaysPerWeek = gymDaysPerWeek
    }
}
