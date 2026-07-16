import Foundation
import SwiftData

@Model
final class FridgeItem {
    var name: String
    var quantity: Double
    var addedAt: Date

    init(name: String, quantity: Double = 1.0, addedAt: Date = Date()) {
        self.name = name
        self.quantity = quantity
        self.addedAt = addedAt
    }
}
