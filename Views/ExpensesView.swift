import SwiftUI

struct ExpensesView: View {
    let vm: ExpensesViewModel
    let app: AppViewModel
    var onDataChange: () -> Void = {}

    var body: some View {
        @Bindable var vm = vm
        List {
            // ── Form ────────────────────────────────────────────────────────
            Section(vm.isEditing ? "Edit Expense" : "Add Expense") {
                DatePicker("Date", selection: $vm.formDate, displayedComponents: .date)

                TextField("Description", text: $vm.formName)

                CategoryPicker(
                    selected: $vm.formCategory,
                    categories: vm.categories,
                    showAddField: $vm.showAddCategoryField,
                    newName: $vm.newCategoryName,
                    onAdd: { vm.addCategory() }
                )

                TextField("Amount", text: $vm.formAmount)
                    .keyboardType(.decimalPad)

                HStack {
                    Button(vm.isEditing ? "Update" : "Add") {
                        vm.save(sheetName: app.currentSheet)
                        onDataChange()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(vm.formName.isEmpty || vm.formCategory.isEmpty || vm.formAmount.isEmpty)

                    if vm.isEditing {
                        Button("Cancel", role: .cancel) { vm.cancelEditing() }
                            .buttonStyle(.bordered)
                    }
                }
            }

            // ── Expense rows ────────────────────────────────────────────────
            Section {
                if vm.pagedExpenses.isEmpty {
                    Text("No expenses for this page.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vm.pagedExpenses) { expense in
                        ExpenseRow(expense: expense)
                            .contentShape(Rectangle())
                            .onTapGesture { vm.startEditing(expense) }
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    vm.delete(expense, sheetName: app.currentSheet)
                                    onDataChange()
                                }
                            }
                    }
                }
            } header: {
                Text("Expenses — \(app.currentSheet)")
            } footer: {
                Text(vm.pageLabel).foregroundStyle(.secondary)
            }

            // ── Pagination ──────────────────────────────────────────────────
            if vm.totalPages > 1 {
                Section {
                    HStack {
                        Button("Previous") { vm.prevPage() }
                            .disabled(vm.currentPage == 1)
                        Spacer()
                        Text("Page \(vm.currentPage) of \(vm.totalPages)")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Next") { vm.nextPage() }
                            .disabled(vm.currentPage == vm.totalPages)
                    }
                }
            }

            // ── Summary ─────────────────────────────────────────────────────
            Section {
                HStack {
                    Text("Total Expenses")
                    Spacer()
                    Text(vm.totalAmount, format: .currency(code: "INR"))
                        .foregroundStyle(.green)
                        .bold()
                }
            }
        }
        .navigationTitle("Expenses")
        .toolbar { sheetToolbar }
        .onAppear { vm.load(sheetName: app.currentSheet) }
    }

    @ToolbarContentBuilder
    private var sheetToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            SheetPickerMenu(app: app)
        }
        ToolbarItem(placement: .topBarTrailing) {
            FileMenu(app: app)
        }
    }
}

// MARK: - Expense row

private struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(expense.name).bold()
                Spacer()
                Text(expense.amount, format: .currency(code: "INR"))
                    .foregroundStyle(.green)
            }
            HStack {
                Text(expense.category).foregroundStyle(.secondary).font(.caption)
                Spacer()
                Text(expense.date, style: .date).foregroundStyle(.secondary).font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}
