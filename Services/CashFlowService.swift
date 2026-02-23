import Foundation

/// Pure computation — no SwiftData context needed.
struct CashFlowService {

    // MARK: - Totals

    static func totalExpenses(_ expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    static func totalIncome(_ income: [Income]) -> Double {
        income.reduce(0) { $0 + $1.amount }
    }

    static func cashFlow(income: [Income], expenses: [Expense]) -> Double {
        totalIncome(income) - totalExpenses(expenses)
    }

    // MARK: - Category groupings

    static func expensesByCategory(_ expenses: [Expense]) -> [String: Double] {
        Dictionary(grouping: expenses, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    static func incomeByCategory(_ income: [Income]) -> [String: Double] {
        Dictionary(grouping: income, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    // MARK: - Monthly groupings (keyed "yyyy-MM")

    static func expensesByMonth(_ expenses: [Expense]) -> [String: Double] {
        Dictionary(grouping: expenses, by: { monthKey($0.date) })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    static func incomeByMonth(_ income: [Income]) -> [String: Double] {
        Dictionary(grouping: income, by: { monthKey($0.date) })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    // MARK: - Drill-down helpers

    /// Expenses in a given category and month (yyyy-MM).
    static func expenses(_ expenses: [Expense], category: String, month: String) -> [Expense] {
        expenses.filter { $0.category == category && monthKey($0.date) == month }
    }

    /// Income in a given category and month (yyyy-MM).
    static func income(_ income: [Income], category: String, month: String) -> [Income] {
        income.filter { $0.category == category && monthKey($0.date) == month }
    }

    // MARK: - Private

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f
    }()

    static func monthKey(_ date: Date) -> String {
        monthFormatter.string(from: date)
    }
}
