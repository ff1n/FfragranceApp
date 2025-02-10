import SwiftUI
import SwiftData

struct AddIngredientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedChemical: AromaChemical?
    @State private var amountGrams: Double = 0.0
    @State private var dilutionPercentage: Double = 100.0
    @State private var showChemicalSelector = false
    
    let formula: Formula
    let onAddIngredient: (AromaChemical, Double, Double) -> Void

    private var totalFormulaWeight: Double {
        formula.totalLineWeight
    }

    private var currentPercentage: Double {
        let prospectiveTotal = totalFormulaWeight + amountGrams
        guard prospectiveTotal > 0 else { return 0 }
        return (amountGrams / prospectiveTotal) * 100
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Select Ingredient") {
                    if let chemical = selectedChemical {
                        ChemicalSelectRow(chemical: chemical)
                    } else {
                        Button("Choose Chemical") {
                            showChemicalSelector = true
                        }
                    }
                }

                Section("Amount") {
                    HStack {
                        Text("Amount (g)")
                        Spacer()
                        TextField("0.0", value: $amountGrams, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Dilution (%)")
                        Spacer()
                        TextField("100", value: $dilutionPercentage, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                    }
                }

                if let chemical = selectedChemical {
                    Section("Information") {
                        if let safeLimit = chemical.ifraSafeLimit {
                            Text("IFRA Limit: \(safeLimit, specifier: "%.2f")%")
                            
                            // The current raw percentage in formula (before dilution)
                            Text("Current % (raw in formula): \(currentPercentage, specifier: "%.2f")%")
                            
                            // Calculate the actual mass after dilution
                            let pureMass = amountGrams * (dilutionPercentage / 100.0)
                            let finalConc = totalFormulaWeight > 0
                                ? (pureMass / (totalFormulaWeight + amountGrams)) * 100
                                : 0.0
                            
                            Text("Final Concentration (factoring dilution): \(finalConc, specifier: "%.2f")%")
                                .foregroundColor(
                                    finalConc > safeLimit ? .red : .primary
                                )
                        } else {
                            Text("No IFRA limit set")
                        }
                    }               }

                Section {
                    Text(String(format: "Total Formula Weight: %.3f g", formula.totalLineWeight + amountGrams))
                }
            }
            .navigationTitle("Add Chemical")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let chemical = selectedChemical else { return }
                        onAddIngredient(chemical, amountGrams, dilutionPercentage)
                        dismiss()
                    }
                    .disabled(selectedChemical == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showChemicalSelector) {
                ChemicalSelectorView { chemical in
                    selectedChemical = chemical
                    // Set the dilution percentage to the chemical's stored value if available
                    if let dilution = chemical.dilutionPercentage {
                        dilutionPercentage = dilution
                    }
                }
            }
        }
    }
}
