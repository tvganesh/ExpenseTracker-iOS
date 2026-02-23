import Foundation

enum ChartMode {
    case cashFlowTrend           // bar: income vs expenses by month
    case expenseByCategory       // pie: expenses by category
    case incomeByCategory        // pie: income by category
    case monthlyExpenseComparison // line/bar: selected expense categories over months
    case monthlyIncomeComparison  // line/bar: selected income categories over months
}

@Observable
@MainActor
class ChartsViewModel {

    var chartMode: ChartMode = .cashFlowTrend

    // MARK: - Computed chart data (updated by calling update())

    /// Sorted list of months present in the data ("yyyy-MM")
    var months: [String] = []

    /// Income per month, aligned to `months`
    var incomeByMonth: [Double] = []

    /// Expenses per month, aligned to `months`
    var expensesByMonth: [Double] = []

    /// All expense categories with their totals, sorted descending
    var expenseCategories: [(category: String, amount: Double)] = []

    /// All income categories with their totals, sorted descending
    var incomeCategories: [(category: String, amount: Double)] = []

    // MARK: - Drill-down state

    /// Tapped category in a pie/bar chart (filters the detail table below)
    var selectedDrilldownCategory: String?

    /// Tapped month key for comparison drill-down
    var selectedDrilldownMonth: String?

    // MARK: - Category comparison selection

    /// Which expense categories are toggled on in the comparison chart
    var selectedExpenseCategories: Set<String> = []

    /// Which income categories are toggled on in the comparison chart
    var selectedIncomeCategories: Set<String> = []

    // MARK: - Update from raw data

    func update(expenses: [Expense], income: [Income]) {
        // Monthly maps
        let expMap = CashFlowService.expensesByMonth(expenses)
        let incMap = CashFlowService.incomeByMonth(income)
        let allMonths = Set(expMap.keys).union(incMap.keys).sorted()

        months          = allMonths
        expensesByMonth = allMonths.map { expMap[$0] ?? 0 }
        incomeByMonth   = allMonths.map { incMap[$0] ?? 0 }

        // Category totals
        let expCat = CashFlowService.expensesByCategory(expenses)
        expenseCategories = expCat
            .sorted { $0.value > $1.value }
            .map { (category: $0.key, amount: $0.value) }

        let incCat = CashFlowService.incomeByCategory(income)
        incomeCategories = incCat
            .sorted { $0.value > $1.value }
            .map { (category: $0.key, amount: $0.value) }

        // Seed default comparison selections (top 3 categories) when empty
        if selectedExpenseCategories.isEmpty {
            selectedExpenseCategories = Set(expenseCategories.prefix(3).map(\.category))
        }
        if selectedIncomeCategories.isEmpty {
            selectedIncomeCategories = Set(incomeCategories.prefix(3).map(\.category))
        }
    }

    // MARK: - Comparison data (per-category series across months)

    /// Returns a series of monthly amounts for one expense category, aligned to `months`.
    func expenseSeries(for category: String, expenses: [Expense]) -> [Double] {
        let monthMap = Dictionary(
            grouping: expenses.filter { $0.category == category },
            by: { CashFlowService.monthKey($0.date) }
        ).mapValues { $0.reduce(0) { $0 + $1.amount } }
        return months.map { monthMap[$0] ?? 0 }
    }

    /// Returns a series of monthly amounts for one income category, aligned to `months`.
    func incomeSeries(for category: String, income: [Income]) -> [Double] {
        let monthMap = Dictionary(
            grouping: income.filter { $0.category == category },
            by: { CashFlowService.monthKey($0.date) }
        ).mapValues { $0.reduce(0) { $0 + $1.amount } }
        return months.map { monthMap[$0] ?? 0 }
    }

    // MARK: - Drill-down helpers

    func drilledExpenses(from expenses: [Expense]) -> [Expense] {
        guard let cat = selectedDrilldownCategory else { return [] }
        if let month = selectedDrilldownMonth {
            return CashFlowService.expenses(expenses, category: cat, month: month)
        }
        return expenses.filter { $0.category == cat }
    }

    func drilledIncome(from income: [Income]) -> [Income] {
        guard let cat = selectedDrilldownCategory else { return [] }
        if let month = selectedDrilldownMonth {
            return CashFlowService.income(income, category: cat, month: month)
        }
        return income.filter { $0.category == cat }
    }

    func clearDrilldown() {
        selectedDrilldownCategory = nil
        selectedDrilldownMonth = nil
    }
}
