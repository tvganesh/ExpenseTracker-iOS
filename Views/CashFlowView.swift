import SwiftUI

struct CashFlowView: View {
    let vm: CashFlowViewModel
    let app: AppViewModel

    var body: some View {
        List {
            // ── Summary cards ────────────────────────────────────────────────
            Section {
                SummaryCard(label: "Total Income",
                            amount: vm.totalIncome,
                            color: .blue)
                SummaryCard(label: "Total Expenses",
                            amount: vm.totalExpenses,
                            color: .green)
                SummaryCard(label: "Cash Flow",
                            amount: vm.cashFlow,
                            color: vm.isPositive ? .mint : .red)
            } header: {
                Text("Summary — \(app.currentSheet)")
            }

            // ── Expense breakdown ────────────────────────────────────────────
            if !vm.expensesByCategory.isEmpty {
                Section("Expenses by Category") {
                    ForEach(vm.expensesByCategory, id: \.category) { item in
                        HStack {
                            Text(item.category)
                            Spacer()
                            Text(item.amount, format: .currency(code: "INR"))
                                .foregroundStyle(.green)
                        }
                    }
                }
            }

            // ── Income breakdown ─────────────────────────────────────────────
            if !vm.incomeByCategory.isEmpty {
                Section("Income by Category") {
                    ForEach(vm.incomeByCategory, id: \.category) { item in
                        HStack {
                            Text(item.category)
                            Spacer()
                            Text(item.amount, format: .currency(code: "INR"))
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Cash Flow")
        .toolbar {
            ToolbarItem(placement: .navigation) { SheetPickerMenu(app: app) }
            ToolbarItem(placement: .primaryAction) { FileMenu(app: app) }
        }
    }
}

// MARK: - Summary card row

private struct SummaryCard: View {
    let label: String
    let amount: Double
    let color: Color

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(amount, format: .currency(code: "INR"))
                .bold()
                .foregroundStyle(color)
        }
        .padding(.vertical, 4)
    }
}
