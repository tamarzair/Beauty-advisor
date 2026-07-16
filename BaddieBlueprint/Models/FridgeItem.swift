import Foundation
import SwiftData

@Model
final class FridgeItem {
    var id: UUID
    var name: String
    var quantity: Int
    var addedAt: Date

    init(id: UUID = UUID(), name: String, quantity: Int = 1, addedAt: Date = .now) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.addedAt = addedAt
    }
}
