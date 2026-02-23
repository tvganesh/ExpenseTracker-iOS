import Foundation
import SwiftData

enum SheetError: LocalizedError {
    case alreadyExists
    case cannotDeleteDefault

    var errorDescription: String? {
        switch self {
        case .alreadyExists:        return "A sheet with this name already exists."
        case .cannotDeleteDefault:  return "The default sheet cannot be deleted."
        }
    }
}

@MainActor
class SheetService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchSheets() throws -> [Sheet] {
        let descriptor = FetchDescriptor<Sheet>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    /// Inserts the "default" sheet if it doesn't already exist. Call on app launch.
    func ensureDefaultSheet() throws {
        let name = "default"
        let predicate = #Predicate<Sheet> { $0.name == name }
        let descriptor = FetchDescriptor<Sheet>(predicate: predicate)
        if try context.fetch(descriptor).isEmpty {
            context.insert(Sheet(name: name))
        }
    }

    func addSheet(name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let predicate = #Predicate<Sheet> { $0.name == trimmed }
        let descriptor = FetchDescriptor<Sheet>(predicate: predicate)
        guard try context.fetch(descriptor).isEmpty else {
            throw SheetError.alreadyExists
        }
        context.insert(Sheet(name: trimmed))
    }

    /// Deletes a sheet and all its expenses and income. "default" cannot be deleted.
    func deleteSheet(name: String, dataService: DataService) throws {
        guard name != "default" else { throw SheetError.cannotDeleteDefault }

        try dataService.clearSheet(name)

        let predicate = #Predicate<Sheet> { $0.name == name }
        let descriptor = FetchDescriptor<Sheet>(predicate: predicate)
        let sheets = try context.fetch(descriptor)
        sheets.forEach { context.delete($0) }
    }
}
