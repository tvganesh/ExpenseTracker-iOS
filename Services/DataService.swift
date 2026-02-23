import Foundation
import SwiftData

@MainActor
class DataService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Expenses

    func fetchExpenses(sheetName: String) throws -> [Expense] {
        let predicate = #Predicate<Expense> { $0.sheetName == sheetName }
        let descriptor = FetchDescriptor<Expense>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func addExpense(date: Date, name: String, category: String, amount: Double, sheetName: String) {
        let expense = Expense(date: date, name: name, category: category, amount: amount, sheetName: sheetName)
        context.insert(expense)
    }

    func updateExpense(_ expense: Expense, date: Date, name: String, category: String, amount: Double) {
        expense.date = date
        expense.name = name
        expense.category = category
        expense.amount = amount
    }

    func deleteExpense(_ expense: Expense) {
        context.delete(expense)
    }

    func deleteAllExpenses(sheetName: String) throws {
        let expenses = try fetchExpenses(sheetName: sheetName)
        expenses.forEach { context.delete($0) }
    }

    // MARK: - Income

    func fetchIncome(sheetName: String) throws -> [Income] {
        let predicate = #Predicate<Income> { $0.sheetName == sheetName }
        let descriptor = FetchDescriptor<Income>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func addIncome(date: Date, name: String, category: String, amount: Double, sheetName: String) {
        let income = Income(date: date, name: name, category: category, amount: amount, sheetName: sheetName)
        context.insert(income)
    }

    func updateIncome(_ income: Income, date: Date, name: String, category: String, amount: Double) {
        income.date = date
        income.name = name
        income.category = category
        income.amount = amount
    }

    func deleteIncome(_ income: Income) {
        context.delete(income)
    }

    func deleteAllIncome(sheetName: String) throws {
        let incomeItems = try fetchIncome(sheetName: sheetName)
        incomeItems.forEach { context.delete($0) }
    }

    // MARK: - Clear sheet

    func clearSheet(_ sheetName: String) throws {
        try deleteAllExpenses(sheetName: sheetName)
        try deleteAllIncome(sheetName: sheetName)
    }
}
