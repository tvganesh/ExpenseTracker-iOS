import Foundation
import SwiftData

@Model
final class Income {
    var date: Date
    var name: String        // maps to `income` column in SQLite
    var category: String
    var amount: Double
    var sheetName: String

    init(date: Date, name: String, category: String, amount: Double, sheetName: String) {
        self.date = date
        self.name = name
        self.category = category
        self.amount = amount
        self.sheetName = sheetName
    }
}
