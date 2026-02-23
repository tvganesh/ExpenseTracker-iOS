import SwiftUI

struct IncomeView: View {
    let vm: IncomeViewModel
    let app: AppViewModel
    var onDataChange: () -> Void = {}

    var body: some View {
        @Bindable var vm = vm
        List {
            // ── Form ────────────────────────────────────────────────────────
            Section(vm.isEditing ? "Edit Income" : "Add Income") {
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
                    .tint(.blue)
                    .disabled(vm.formName.isEmpty || vm.formCategory.isEmpty || vm.formAmount.isEmpty)

                    if vm.isEditing {
                        Button("Cancel", role: .cancel) { vm.cancelEditing() }
                            .buttonStyle(.bordered)
                    }
                }
            }

            // ── Income rows ─────────────────────────────────────────────────
            Section {
                if vm.pagedIncome.isEmpty {
                    Text("No income for this page.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vm.pagedIncome) { income in
                        IncomeRow(income: income)
                            .contentShape(Rectangle())
                            .onTapGesture { vm.startEditing(income) }
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    vm.delete(income, sheetName: app.currentSheet)
                                    onDataChange()
                                }
                            }
                    }
                }
            } header: {
                Text("Income — \(app.currentSheet)")
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
                    Text("Total Income")
                    Spacer()
                    Text(vm.totalAmount, format: .currency(code: "INR"))
                        .foregroundStyle(.blue)
                        .bold()
                }
            }
        }
        .navigationTitle("Income")
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

// MARK: - Income row

private struct IncomeRow: View {
    let income: Income

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(income.name).bold()
                Spacer()
                Text(income.amount, format: .currency(code: "INR"))
                    .foregroundStyle(.blue)
            }
            HStack {
                Text(income.category).foregroundStyle(.secondary).font(.caption)
                Spacer()
                Text(income.date, style: .date).foregroundStyle(.secondary).font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}
