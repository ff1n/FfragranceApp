import SwiftUI
import SwiftData

struct EditComponentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var formula: Formula
    @Bindable var line: FormulaLine
    @State private var amountGrams: Double
    
    init(formula: Formula, line: FormulaLine) {
        self.formula = formula
        self.line = line
        self._amountGrams = State(initialValue: line.amountGrams)
    }
    
    private var totalFormulaWeight: Double {
        guard let lines = formula.lines else { return 0.0 }
        return lines.reduce(0.0) { total, currentLine in
            total + (currentLine.id == line.id ? amountGrams : currentLine.amountGrams)
        }
    }
    
    private var currentPercentage: Double {
        guard totalFormulaWeight > 0 else { return 0 }
        return (amountGrams / totalFormulaWeight) * 100
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Amount (g)")
                        Spacer()
                        TextField("0.0", value: $amountGrams, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Percentage in Formula")
                        Spacer()
                        Text("\(currentPercentage, specifier: "%.2f")%")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Amount")
                }
                
                if let chemical = line.chemical {
                    Section {
                        if let chemical = line.chemical {
                            if let safeLimit = chemical.ifraSafeLimit {
                                Text("IFRA Limit: \(safeLimit, specifier: "%.2f")%")
                                
                                // Calculate actual mass after dilution
                                let pureMass = amountGrams * (line.dilutionPercentage / 100.0)
                                let finalConcentration = totalFormulaWeight > 0
                                    ? (pureMass / totalFormulaWeight) * 100
                                    : 0.0
                                
                                Text("Final Concentration: \(finalConcentration, specifier: "%.2f")%")
                                    .foregroundColor(
                                        finalConcentration > safeLimit ? .red : .primary
                                    )
                            } else {
                                Text("No IFRA limit set")
                            }
                        }
                    } header: {
                        Text("Information")
                    }                }
                
                Section {
                    Text("Total Formula Weight: \(totalFormulaWeight, specifier: "%.3f")g")
                } header: {
                    Text("Summary")
                }
            }
            .navigationTitle("Edit Component")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        line.amountGrams = amountGrams
                        try? modelContext.save()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
