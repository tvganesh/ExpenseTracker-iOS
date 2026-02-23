import Foundation
import SwiftData

// NOTE: Full .xlsx import requires a Swift Package that can read ZIP archives.
// To enable it, add the CoreXLSX package to the project:
//   File > Add Package Dependencies > https://github.com/CoreOffice/CoreXLSX
// Until then, this service provides CSV import/export which covers the same data.

@MainActor
class ExcelService {
    private let dataService: DataService

    init(dataService: DataService) {
        self.dataService = dataService
    }

    // MARK: - CSV Export

    /// Returns a CSV string with all expenses and income for a sheet.
    func exportCSV(sheetName: String) throws -> String {
        let expenses = try dataService.fetchExpenses(sheetName: sheetName)
        let income   = try dataService.fetchIncome(sheetName: sheetName)

        var lines = ["type,date,name,category,amount"]

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        for e in expenses {
            let row = "expense,\(formatter.string(from: e.date)),\(csvEscape(e.name)),\(csvEscape(e.category)),\(e.amount)"
            lines.append(row)
        }
        for i in income {
            let row = "income,\(formatter.string(from: i.date)),\(csvEscape(i.name)),\(csvEscape(i.category)),\(i.amount)"
            lines.append(row)
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - CSV Import

    /// Parses a CSV string (exported by exportCSV) and inserts records into the given sheet.
    func importCSV(_ csv: String, sheetName: String) throws {
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard lines.count > 1 else { return }   // header only → nothing to import

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        for line in lines.dropFirst() {         // skip header
            let fields = parseCSVLine(line)
            guard fields.count == 5 else { continue }

            let type     = fields[0].lowercased()
            let dateStr  = fields[1]
            let name     = fields[2]
            let category = fields[3]
            guard let amount = Double(fields[4]),
                  let date   = formatter.date(from: dateStr) else { continue }

            switch type {
            case "expense":
                dataService.addExpense(date: date, name: name, category: category,
                                       amount: amount, sheetName: sheetName)
            case "income":
                dataService.addIncome(date: date, name: name, category: category,
                                      amount: amount, sheetName: sheetName)
            default:
                break
            }
        }
    }

    // MARK: - Excel serial date conversion (mirrors JS excelDateToJSDate)

    /// Converts an Excel serial date number to a Swift Date.
    static func excelSerialToDate(_ serial: Double) -> Date? {
        // Excel epoch is 1899-12-30 (with the Lotus 1-2-3 1900 leap-year bug)
        let excelEpoch = Date(timeIntervalSince1970: -2209161600) // 1899-12-30 UTC
        let seconds = (serial - 1) * 86400      // subtract 1 for the Lotus bug
        return excelEpoch.addingTimeInterval(seconds)
    }

    // MARK: - Private helpers

    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let c = line[i]
            if c == "\"" {
                let next = line.index(after: i)
                if inQuotes && next < line.endIndex && line[next] == "\"" {
                    current.append("\"")
                    i = line.index(after: next)
                    continue
                }
                inQuotes.toggle()
            } else if c == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(c)
            }
            i = line.index(after: i)
        }
        fields.append(current)
        return fields
    }
}
