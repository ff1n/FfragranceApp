import SwiftUI

struct AddFormulaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var formula = Formula(name: "")

    var body: some View {
        NavigationStack {
            FormulaDetailView(formula: formula, isNewFormula: true)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            modelContext.insert(formula)
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) {
                            dismiss()
                        }
                    }
                }
        }
    }
}
