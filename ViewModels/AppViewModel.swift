import Foundation
import SwiftData

enum AppSection {
    case expenses, income, cashflow, charts
}

@Observable
@MainActor
class AppViewModel {
    var sheets: [String] = ["default"]
    var currentSheet: String = "default"
    var selectedSection: AppSection = .expenses
    var errorMessage: String?

    // Sheet modal state
    var showNewSheetSheet: Bool = false
    var newSheetName: String = ""
    var showDeleteSheetSheet: Bool = false
    var sheetToDelete: String = ""

    private let sheetService: SheetService
    private let dataService: DataService

    init(context: ModelContext) {
        self.dataService = DataService(context: context)
        self.sheetService = SheetService(context: context)
    }

    func onAppear() {
        do {
            try sheetService.ensureDefaultSheet()
            sheets = try sheetService.fetchSheets().map(\.name)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createSheet() {
        do {
            try sheetService.addSheet(name: newSheetName)
            sheets = try sheetService.fetchSheets().map(\.name)
            currentSheet = newSheetName.trimmingCharacters(in: .whitespaces)
            newSheetName = ""
            showNewSheetSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteSheet() {
        guard !sheetToDelete.isEmpty else { return }
        do {
            try sheetService.deleteSheet(name: sheetToDelete, dataService: dataService)
            sheets = try sheetService.fetchSheets().map(\.name)
            if currentSheet == sheetToDelete { currentSheet = "default" }
            sheetToDelete = ""
            showDeleteSheetSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
