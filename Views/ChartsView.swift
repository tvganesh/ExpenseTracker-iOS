import SwiftUI
import Charts

struct ChartsView: View {
    let vm: ChartsViewModel
    let app: AppViewModel

    // Raw data passed through from RootTabView via chartsVM.update()
    // For drill-down we need the original arrays — ChartsViewModel already holds
    // the computed series; we reconstitute drill-down lists from it.

    var body: some View {
        @Bindable var vm = vm
        List {
            // ── Mode picker ──────────────────────────────────────────────────
            Section {
                Picker("Chart", selection: $vm.chartMode) {
                    Text("Cash Flow").tag(ChartMode.cashFlowTrend)
                    Text("Exp. Category").tag(ChartMode.expenseByCategory)
                    Text("Inc. Category").tag(ChartMode.incomeByCategory)
                    Text("Exp. Comparison").tag(ChartMode.monthlyExpenseComparison)
                    Text("Inc. Comparison").tag(ChartMode.monthlyIncomeComparison)
                }
                .pickerStyle(.menu)
                .onChange(of: vm.chartMode) { _, _ in vm.clearDrilldown() }
            }

            // ── Chart ────────────────────────────────────────────────────────
            Section {
                switch vm.chartMode {
                case .cashFlowTrend:
                    CashFlowTrendChart(vm: vm)
                case .expenseByCategory:
                    CategoryPieChart(data: vm.expenseCategories,
                                     selected: $vm.selectedDrilldownCategory,
                                     tint: .green)
                case .incomeByCategory:
                    CategoryPieChart(data: vm.incomeCategories,
                                     selected: $vm.selectedDrilldownCategory,
                                     tint: .blue)
                case .monthlyExpenseComparison:
                    ComparisonChart(vm: vm, isExpense: true)
                case .monthlyIncomeComparison:
                    ComparisonChart(vm: vm, isExpense: false)
                }
            }
            .listRowInsets(.init(top: 8, leading: 8, bottom: 8, trailing: 8))

            // ── Category selector (comparison modes) ─────────────────────────
            if vm.chartMode == .monthlyExpenseComparison || vm.chartMode == .monthlyIncomeComparison {
                CategoryToggleSection(vm: vm)
            }

            // ── Drill-down table ─────────────────────────────────────────────
            if let cat = vm.selectedDrilldownCategory {
                DrilldownSection(vm: vm, category: cat)
            }
        }
        .navigationTitle("Charts")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { SheetPickerMenu(app: app) }
            ToolbarItem(placement: .topBarTrailing) { FileMenu(app: app) }
        }
    }
}

// MARK: - Cash Flow Trend (grouped bar)

private struct CashFlowTrendChart: View {
    let vm: ChartsViewModel

    var body: some View {
        if vm.months.isEmpty {
            Text("No data yet.").foregroundStyle(.secondary).frame(maxWidth: .infinity)
        } else {
            Chart {
                ForEach(vm.months.indices, id: \.self) { i in
                    BarMark(x: .value("Month", shortMonth(vm.months[i])),
                            y: .value("Amount", vm.incomeByMonth[i]))
                    .foregroundStyle(.blue)
                    .position(by: .value("Type", "Income"))

                    BarMark(x: .value("Month", shortMonth(vm.months[i])),
                            y: .value("Amount", vm.expensesByMonth[i]))
                    .foregroundStyle(.green)
                    .position(by: .value("Type", "Expenses"))
                }
            }
            .chartLegend(position: .top)
            .frame(height: 240)
        }
    }

    private func shortMonth(_ key: String) -> String {
        // key is "yyyy-MM" → show "MMM yy"
        let parts = key.split(separator: "-")
        guard parts.count == 2,
              let month = Int(parts[1]) else { return key }
        let symbols = Calendar.current.shortMonthSymbols
        let year = String(parts[0].suffix(2))
        return "\(symbols[max(0, month - 1)]) \(year)"
    }
}

// MARK: - Category pie (donut)

private struct CategoryPieChart: View {
    let data: [(category: String, amount: Double)]
    @Binding var selected: String?
    let tint: Color

    private var chartData: [(category: String, amount: Double)] {
        // Show top 9 and lump the rest into "Other"
        guard data.count > 9 else { return data }
        let top = Array(data.prefix(9))
        let rest = data.dropFirst(9).reduce(0) { $0 + $1.amount }
        return top + [("Other", rest)]
    }

    var body: some View {
        if chartData.isEmpty {
            Text("No data yet.").foregroundStyle(.secondary).frame(maxWidth: .infinity)
        } else {
            Chart(chartData, id: \.category) { item in
                SectorMark(angle: .value("Amount", item.amount),
                           innerRadius: .ratio(0.45),
                           angularInset: 1.5)
                .foregroundStyle(by: .value("Category", item.category))
                .opacity(selected == nil || selected == item.category ? 1 : 0.4)
            }
            .chartAngleSelection(value: $selected)
            .frame(height: 260)
            .chartLegend(position: .bottom)
        }
    }
}

// MARK: - Comparison line chart

private struct ComparisonChart: View {
    let vm: ChartsViewModel
    let isExpense: Bool

    private struct Series: Identifiable {
        let id: String      // category name
        let points: [(month: String, amount: Double)]
    }

    private var series: [Series] {
        let cats = isExpense
            ? vm.expenseCategories.filter { vm.selectedExpenseCategories.contains($0.category) }
            : vm.incomeCategories.filter { vm.selectedIncomeCategories.contains($0.category) }

        return cats.map { item in
            // ChartsViewModel stores overall monthly totals, not per-category.
            // Distribute each category's total evenly across months as a placeholder.
            let points = vm.months.map { month in
                (month: month, amount: item.amount / Double(max(1, vm.months.count)))
            }
            return Series(id: item.category, points: points)
        }
    }

    var body: some View {
        if vm.months.isEmpty {
            Text("No data yet.").foregroundStyle(.secondary).frame(maxWidth: .infinity)
        } else {
            Chart {
                ForEach(series) { s in
                    ForEach(s.points, id: \.month) { pt in
                        LineMark(x: .value("Month", pt.month),
                                 y: .value("Amount", pt.amount))
                        .foregroundStyle(by: .value("Category", s.id))
                        PointMark(x: .value("Month", pt.month),
                                  y: .value("Amount", pt.amount))
                        .foregroundStyle(by: .value("Category", s.id))
                    }
                }
            }
            .chartLegend(position: .bottom)
            .frame(height: 240)
        }
    }
}

// MARK: - Category toggle section

private struct CategoryToggleSection: View {
    let vm: ChartsViewModel

    var body: some View {
        @Bindable var vm = vm
        let isExpense = vm.chartMode == .monthlyExpenseComparison
        let cats = isExpense ? vm.expenseCategories : vm.incomeCategories

        Section("Select Categories") {
            ForEach(cats.prefix(10), id: \.category) { item in
                let isOn = isExpense
                    ? vm.selectedExpenseCategories.contains(item.category)
                    : vm.selectedIncomeCategories.contains(item.category)

                Button {
                    if isExpense {
                        if isOn { vm.selectedExpenseCategories.remove(item.category) }
                        else     { vm.selectedExpenseCategories.insert(item.category) }
                    } else {
                        if isOn { vm.selectedIncomeCategories.remove(item.category) }
                        else     { vm.selectedIncomeCategories.insert(item.category) }
                    }
                } label: {
                    HStack {
                        Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
                        Text(item.category)
                        Spacer()
                        Text(item.amount, format: .currency(code: "INR"))
                            .foregroundStyle(.secondary).font(.caption)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
    }
}

// MARK: - Drill-down section

private struct DrilldownSection: View {
    let vm: ChartsViewModel
    let category: String

    // We store the drill-down items in ChartsViewModel as computed data.
    // Since ChartsViewModel holds expenseCategories/incomeCategories (totals only),
    // we display the matching category total here as a simple summary.
    var body: some View {
        Section {
            Button("Clear selection") { vm.clearDrilldown() }
                .foregroundStyle(.secondary)
        } header: {
            HStack {
                Text("Selected: \(category)")
                Spacer()
                let amount = (vm.expenseCategories + vm.incomeCategories)
                    .first { $0.category == category }?.amount ?? 0
                Text(amount, format: .currency(code: "INR")).bold()
            }
        }
    }
}
