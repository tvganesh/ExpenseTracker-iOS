import Foundation
import SwiftData

@Observable
@MainActor
class IncomeViewModel {

    // MARK: - List state
    var income: [Income] = []
    var currentPage: Int = 1
    let rowsPerPage = 15

    var pagedIncome: [Income] {
        let start = (currentPage - 1) * rowsPerPage
        return Array(income.dropFirst(start).prefix(rowsPerPage))
    }

    var totalPages: Int {
        max(1, Int(ceil(Double(income.count) / Double(rowsPerPage))))
    }

    var pageLabel: String {
        let start = (currentPage - 1) * rowsPerPage + 1
        let end = min(currentPage * rowsPerPage, income.count)
        return income.isEmpty ? "No entries" : "Showing \(start)–\(end) of \(income.count)"
    }

    // MARK: - Form state
    var formDate: Date = Date()
    var formName: String = ""
    var formCategory: String = IncomeViewModel.defaultCategories.first ?? ""
    var formAmount: String = ""
    var editingIncome: Income?
    var isEditing: Bool { editingIncome != nil }

    // MARK: - Category state
    var categories: [String] = IncomeViewModel.defaultCategories
    var showAddCategoryField: Bool = false
    var newCategoryName: String = ""

    // MARK: - UI state
    var errorMessage: String?

    // MARK: - Totals
    var totalAmount: Double = 0

    private let dataService: DataService

    init(context: ModelContext) {
        self.dataService = DataService(context: context)
    }

    // MARK: - Data operations

    func load(sheetName: String) {
        do {
            income = try dataService.fetchIncome(sheetName: sheetName)
            totalAmount = income.reduce(0) { $0 + $1.amount }
            currentPage = 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(sheetName: String) {
        guard let amount = Double(formAmount), amount > 0,
              !formName.isEmpty, !formCategory.isEmpty else { return }

        if let editing = editingIncome {
            dataService.updateIncome(editing, date: formDate, name: formName,
                                     category: formCategory, amount: amount)
        } else {
            dataService.addIncome(date: formDate, name: formName, category: formCategory,
                                  amount: amount, sheetName: sheetName)
        }
        resetForm()
        load(sheetName: sheetName)
    }

    func delete(_ income: Income, sheetName: String) {
        dataService.deleteIncome(income)
        load(sheetName: sheetName)
    }

    // MARK: - Editing

    func startEditing(_ income: Income) {
        editingIncome = income
        formDate = income.date
        formName = income.name
        formCategory = income.category
        formAmount = String(income.amount)
    }

    func cancelEditing() {
        resetForm()
    }

    // MARK: - Categories

    func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !categories.contains(trimmed) else {
            showAddCategoryField = false
            newCategoryName = ""
            return
        }
        categories.append(trimmed)
        formCategory = trimmed
        showAddCategoryField = false
        newCategoryName = ""
    }

    // MARK: - Pagination

    func nextPage() { if currentPage < totalPages { currentPage += 1 } }
    func prevPage() { if currentPage > 1 { currentPage -= 1 } }

    // MARK: - Private

    private func resetForm() {
        editingIncome = nil
        formDate = Date()
        formName = ""
        formCategory = categories.first ?? ""
        formAmount = ""
    }

    // MARK: - Default categories (mirrors Next.js source)

    static let defaultCategories: [String] = [
        "rent received", "interest", "annuity", "salary",
        "stock profit", "stock loss", "stock dividend",
        "corporate fd", "bond interest", "SWP", "other"
    ]
}
