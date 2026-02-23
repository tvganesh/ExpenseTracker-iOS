import SwiftUI

// MARK: - Sheet picker menu (toolbar leading)
// Shows which sheet is active and lets the user switch.

struct SheetPickerMenu: View {
    let app: AppViewModel

    var body: some View {
        Menu {
            ForEach(app.sheets, id: \.self) { sheet in
                Button {
                    app.currentSheet = sheet
                } label: {
                    if sheet == app.currentSheet {
                        Label(sheet, systemImage: "checkmark")
                    } else {
                        Text(sheet)
                    }
                }
            }
        } label: {
            Label(app.currentSheet, systemImage: "doc.text")
        }
    }
}

// MARK: - File menu (toolbar trailing)
// New Sheet / Delete Sheet / Import / Export / Clear all records.

struct FileMenu: View {
    let app: AppViewModel

    var body: some View {
        Menu("File") {
            Button("New Sheet")    { app.showNewSheetSheet = true }
            Button("Delete Sheet") { app.showDeleteSheetSheet = true }
            Divider()
            // Import / Export — hooked up when ExcelService xlsx support is added
            Button("Import (CSV)", action: {})   // TODO: wire to document picker
            Button("Export (CSV)", action: {})   // TODO: wire to share sheet
        }
    }
}

// MARK: - Category picker + inline add-new field

struct CategoryPicker: View {
    @Binding var selected: String
    let categories: [String]
    @Binding var showAddField: Bool
    @Binding var newName: String
    var onAdd: () -> Void

    var body: some View {
        if showAddField {
            HStack {
                TextField("New category", text: $newName)
                Button("Add") { onAdd() }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                Button("Cancel") {
                    showAddField = false
                    newName = ""
                }
                .foregroundStyle(.red)
            }
        } else {
            Picker("Category", selection: $selected) {
                Text("Select…").tag("")
                ForEach(categories, id: \.self) { Text($0).tag($0) }
                Divider()
                Text("Add new…").tag("__add_new__")
            }
            .onChange(of: selected) { old, new in
                if new == "__add_new__" {
                    selected = old
                    showAddField = true
                }
            }
        }
    }
}
