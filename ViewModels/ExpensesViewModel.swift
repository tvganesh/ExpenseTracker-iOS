import Foundation
import SwiftData

@Observable
@MainActor
class ExpensesViewModel {

    // MARK: - List state
    var expenses: [Expense] = []
    var currentPage: Int = 1
    let rowsPerPage = 15

    var pagedExpenses: [Expense] {
        let start = (currentPage - 1) * rowsPerPage
        return Array(expenses.dropFirst(start).prefix(rowsPerPage))
    }

    var totalPages: Int {
        max(1, Int(ceil(Double(expenses.count) / Double(rowsPerPage))))
    }

    var pageLabel: String {
        let start = (currentPage - 1) * rowsPerPage + 1
        let end = min(currentPage * rowsPerPage, expenses.count)
        return expenses.isEmpty ? "No entries" : "Showing \(start)–\(end) of \(expenses.count)"
    }

    // MARK: - Form state
    var formDate: Date = Date()
    var formName: String = ""
    var formCategory: String = ExpensesViewModel.defaultCategories.first ?? ""
    var formAmount: String = ""
    var editingExpense: Expense?
    var isEditing: Bool { editingExpense != nil }

    // MARK: - Category state
    var categories: [String] = ExpensesViewModel.defaultCategories
    var showAddCategoryField: Bool = false
    var newCategoryName: String = ""

    // MARK: - UI state
    var errorMessage: String?

    // MARK: - Totals (kept in sync after every load)
    var totalAmount: Double = 0

    private let dataService: DataService

    init(context: ModelContext) {
        self.dataService = DataService(context: context)
    }

    // MARK: - Data operations

    func load(sheetName: String) {
        do {
            expenses = try dataService.fetchExpenses(sheetName: sheetName)
            totalAmount = expenses.reduce(0) { $0 + $1.amount }
            currentPage = 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(sheetName: String) {
        guard let amount = Double(formAmount), amount > 0,
              !formName.isEmpty, !formCategory.isEmpty else { return }

        if let editing = editingExpense {
            dataService.updateExpense(editing, date: formDate, name: formName,
                                      category: formCategory, amount: amount)
        } else {
            dataService.addExpense(date: formDate, name: formName, category: formCategory,
                                   amount: amount, sheetName: sheetName)
        }
        resetForm()
        load(sheetName: sheetName)
    }

    func delete(_ expense: Expense, sheetName: String) {
        dataService.deleteExpense(expense)
        load(sheetName: sheetName)
    }

    // MARK: - Editing

    func startEditing(_ expense: Expense) {
        editingExpense = expense
        formDate = expense.date
        formName = expense.name
        formCategory = expense.category
        formAmount = String(expense.amount)
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
        editingExpense = nil
        formDate = Date()
        formName = ""
        formCategory = categories.first ?? ""
        formAmount = ""
    }

    // MARK: - Default categories (mirrors Next.js source)

    static let defaultCategories: [String] = [
        "grocery", "internet", "misc", "transport", "AI", "petrol", "rent",
        "charity", "college", "doctor & medicines", "food & entertainment",
        "mobile", "pet care", "salary", "electricity", "water", "gas",
        "personal care", "car maintenance", "house maintenance",
        "clothes & accessories", "health & fitness", "shanthi-expense",
        "vacation expenses", "other"
    ]
}
