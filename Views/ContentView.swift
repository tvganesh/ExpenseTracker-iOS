import SwiftUI
import SwiftData

// Root entry point — grabs ModelContext from the environment then hands off
// to RootTabView which can initialise all ViewModels synchronously.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        RootTabView(modelContext: modelContext)
    }
}

struct RootTabView: View {
    @State private var app: AppViewModel
    @State private var expensesVM: ExpensesViewModel
    @State private var incomeVM: IncomeViewModel
    @State private var cashFlowVM: CashFlowViewModel
    @State private var chartsVM: ChartsViewModel

    init(modelContext: ModelContext) {
        _app        = State(initialValue: AppViewModel(context: modelContext))
        _expensesVM = State(initialValue: ExpensesViewModel(context: modelContext))
        _incomeVM   = State(initialValue: IncomeViewModel(context: modelContext))
        _cashFlowVM = State(initialValue: CashFlowViewModel())
        _chartsVM   = State(initialValue: ChartsViewModel())
    }

    var body: some View {
        TabView {
            NavigationStack {
                ExpensesView(vm: expensesVM, app: app, onDataChange: syncDerived)
            }
            .tabItem { Label("Expenses", systemImage: "cart") }

            NavigationStack {
                IncomeView(vm: incomeVM, app: app, onDataChange: syncDerived)
            }
            .tabItem { Label("Income", systemImage: "dollarsign.circle") }

            NavigationStack {
                CashFlowView(vm: cashFlowVM, app: app)
            }
            .tabItem { Label("Cash Flow", systemImage: "arrow.left.arrow.right.circle") }

            NavigationStack {
                ChartsView(vm: chartsVM, app: app)
            }
            .tabItem { Label("Charts", systemImage: "chart.bar.fill") }
        }
        .onAppear {
            app.onAppear()
            reload()
        }
        .onChange(of: app.currentSheet) { _, _ in reload() }
        .onChange(of: expensesVM.totalAmount) { _, _ in syncDerived() }
        .onChange(of: incomeVM.totalAmount) { _, _ in syncDerived() }
        .sheet(isPresented: $app.showNewSheetSheet) { NewSheetSheet(app: app) }
        .sheet(isPresented: $app.showDeleteSheetSheet) { DeleteSheetSheet(app: app) }
        .alert("Error", isPresented: .constant(app.errorMessage != nil)) {
            Button("OK") { app.errorMessage = nil }
        } message: {
            Text(app.errorMessage ?? "")
        }
    }

    private func reload() {
        expensesVM.load(sheetName: app.currentSheet)
        incomeVM.load(sheetName: app.currentSheet)
        syncDerived()
    }

    private func syncDerived() {
        cashFlowVM.update(expenses: expensesVM.expenses, income: incomeVM.income)
        chartsVM.update(expenses: expensesVM.expenses, income: incomeVM.income)
    }
}

// MARK: - Sheet management modals

struct NewSheetSheet: View {
    let app: AppViewModel

    var body: some View {
        @Bindable var app = app
        NavigationStack {
            Form {
                Section("Sheet name") {
                    TextField("e.g. 2025", text: $app.newSheetName)
                }
            }
            .navigationTitle("New Sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        app.newSheetName = ""
                        app.showNewSheetSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { app.createSheet() }
                        .disabled(app.newSheetName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct DeleteSheetSheet: View {
    let app: AppViewModel

    var body: some View {
        @Bindable var app = app
        NavigationStack {
            Form {
                Section("Select sheet to delete") {
                    Picker("Sheet", selection: $app.sheetToDelete) {
                        Text("Choose…").tag("")
                        ForEach(app.sheets.filter { $0 != "default" }, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .pickerStyle(.inline)
                }
                if !app.sheetToDelete.isEmpty {
                    Section {
                        Text("Deleting \"\(app.sheetToDelete)\" removes all its expenses and income. This cannot be undone.")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Delete Sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        app.sheetToDelete = ""
                        app.showDeleteSheetSheet = false
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) { app.deleteSheet() }
                        .disabled(app.sheetToDelete.isEmpty)
                }
            }
        }
    }
}
