import Foundation

@Observable
@MainActor
class CashFlowViewModel {
    var totalExpenses: Double = 0
    var totalIncome: Double = 0
    var cashFlow: Double = 0
    var isPositive: Bool { cashFlow >= 0 }

    // Category breakdowns (for CashFlow summary screen)
    var expensesByCategory: [(category: String, amount: Double)] = []
    var incomeByCategory: [(category: String, amount: Double)] = []

    func update(expenses: [Expense], income: [Income]) {
        totalExpenses = CashFlowService.totalExpenses(expenses)
        totalIncome   = CashFlowService.totalIncome(income)
        cashFlow      = CashFlowService.cashFlow(income: income, expenses: expenses)

        let expCat = CashFlowService.expensesByCategory(expenses)
        expensesByCategory = expCat
            .sorted { $0.value > $1.value }
            .map { (category: $0.key, amount: $0.value) }

        let incCat = CashFlowService.incomeByCategory(income)
        incomeByCategory = incCat
            .sorted { $0.value > $1.value }
            .map { (category: $0.key, amount: $0.value) }
    }
}
