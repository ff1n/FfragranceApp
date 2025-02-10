import SwiftUI
import SwiftData
import Foundation

struct FormulaListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Formula.name, order: .forward)]) private var formulas: [Formula]
    @State private var showAddFormula = false

    var body: some View {
        List {
            ForEach(formulas) { formula in
                NavigationLink(destination: FormulaDetailView(formula: formula)) {
                    VStack(alignment: .leading) {
                        Text(formula.name)
                            .font(.headline)
                        Text(formula.smellDescription ?? "No Description")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteFormulas)
        }
        .navigationTitle("Formulas")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddFormula.toggle() }) {
                    Label("Add Formula", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddFormula) {
            AddFormulaView()
        }
    }

    private func deleteFormulas(at offsets: IndexSet) {
        for index in offsets {
            let formula = formulas[index]
            
            // Explicitly delete all formula lines first
            formula.lines?.forEach { modelContext.delete($0) }
            modelContext.delete(formula)
        }
        
        // Force context refresh
        do {
            try modelContext.save()
        } catch {
            print("Error saving after formula deletion: \(error)")
        }
    }
}
