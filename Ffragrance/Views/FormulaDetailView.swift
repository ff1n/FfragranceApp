import SwiftUI
import SwiftData
import Foundation
import Charts

struct FormulaDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var formula: Formula
    
    var isNewFormula: Bool = false
    
    @State private var showAddIngredientSheet = false
    @State private var showScaleSheet = false
    @State private var newTotalWeight: Double = 0.0
    
    private struct ChartData: Identifiable {
        let id: UUID
        let name: String
        let value: Double
        let color: Color
    }
    
    // Add this computed property
    private var chartData: [ChartData] {
        guard let components = formula.dilutedComponents else { return [] }
        
        let grouped = Dictionary(grouping: components) { component in
            component.chemical.category // Fixed here
        }
        
        return grouped.map { (category, components) in
            let total = components.reduce(0) { $0 + $1.finalConcentration }
            return ChartData(
                id: category?.id ?? UUID(),
                name: category?.name ?? "Uncategorized",
                value: total,
                color: category?.color ?? .gray
            )
        }
    }
    
    var body: some View {
        List {
            formulaDetailsSection
            
            if !chartData.isEmpty {
                 Section("Composition by Category") {
                     Chart(chartData) { data in
                         BarMark(
                             x: .value("Category", data.name),
                             y: .value("Percentage", data.value)
                         )
                         .foregroundStyle(data.color)
                     }
                     .frame(height: 200)
                 }
                 
                 Section("Category Breakdown") {
                     Chart(chartData) { data in
                         SectorMark(
                             angle: .value("Percentage", data.value),
                             innerRadius: .ratio(0.5),
                             angularInset: 1.5
                         )
                         .foregroundStyle(data.color)
                         .annotation(position: .overlay) {
                             Text("\(data.value, specifier: "%.1f")%")
                                 .font(.caption)
                                 .foregroundColor(.white)
                         }
                     }
                     .frame(height: 300)
                 }
             }
             
            
            diluentSection
            componentsSection
            
            // Add Scale button at the bottom
            if let lines = formula.lines, !lines.isEmpty {
                Section {
                    Button(action: {
                        newTotalWeight = formula.totalFormulaWeight
                        showScaleSheet = true
                    }) {
                        HStack {
                            Image(systemName: "scale.3d")
                            Text("Scale Formula")
                        }
                    }
                }
            }
        }
        .navigationTitle(formula.name.isEmpty ? "New Formula" : formula.name)
        .toolbar {
            if !isNewFormula {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveFormula()
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddIngredientSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddIngredientSheet) {
            AddIngredientSheet(formula: formula) { chemical, grams, dilution in
                addIngredient(chemical: chemical, grams: grams, dilution: dilution)
            }
        }
        .sheet(isPresented: $showScaleSheet) {
            NavigationView {
                VStack(spacing: 16) {
                    Text("Scale Formula")
                        .font(.title2)
                        .padding()

                    Text("Current: \(formula.totalFormulaWeight, specifier: "%.2f") g")
                    
                    TextField("New Total Weight (g)", value: $newTotalWeight, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal)
                    
                    HStack {
                        Button("Apply Scaling") {
                            scaleFormula(to: newTotalWeight)
                            showScaleSheet = false
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Spacer()
                        
                        Button("Cancel", role: .cancel) {
                            showScaleSheet = false
                        }
                    }
                    .padding()
                }
                .padding()
            }
            .presentationDetents([.height(300)])
        }
    }
    
    private var formulaDetailsSection: some View {
        Section("Formula Details") {
            TextField("Formula Name", text: $formula.name)
            
            TextEditor(text: Binding(
                get: { formula.smellDescription ?? "" },
                set: { formula.smellDescription = $0 }
            ))
            .frame(height: 80)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private var diluentSection: some View {
        Section("Diluent") {
            Picker("Diluent Type", selection: $formula.diluentType) {
                Text("None").tag(String?.none)
                Text("Perfumer's Alcohol").tag(String?("Perfumer's Alcohol"))
                Text("DPG").tag(String?("DPG"))
            }
            .pickerStyle(.menu)
            
            HStack {
                Text("Diluent Weight (g)")
                Spacer()
                TextField("0.0", value: $formula.diluentWeight, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
            }
            
            HStack {
                Text("Total Formula Weight")
                Spacer()
                Text("\(formula.totalFormulaWeight, specifier: "%.3f") g")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var componentsSection: some View {
        Section {
            if formula.lines?.isEmpty ?? true {
                Text("No ingredients added")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                if let components = formula.dilutedComponents {
                    ForEach(components) { component in       // <- This needs to change
                        IngredientRow(component: component)  // <- Move row content to separate view
                    }
                    .onDelete(perform: deleteLines)
                }
            }
        } header: {
            Text("Components")
        } footer: {
            if !(formula.lines?.isEmpty ?? true) {
                Text("Swipe left to delete an ingredient")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func saveFormula() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving formula: \(error)")
        }
    }
    
    private func addIngredient(chemical: AromaChemical, grams: Double, dilution: Double) {
        let newLine = FormulaLine(
            chemical: chemical,
            amountGrams: grams,
            dilutionPercentage: dilution
        )
        if formula.lines == nil {
            formula.lines = []
        }
        formula.lines?.append(newLine)
        saveFormula()
    }
    
    private func editLine(with lineID: UUID) {
        guard let lines = formula.lines,
              let index = lines.firstIndex(where: { $0.id == lineID }) else { return }
        let line = lines[index]
        print("Edit line: \(line.chemical?.name ?? "Unknown") (\(line.id))")
    }
    
    private func deleteLines(at offsets: IndexSet) {
        guard let lines = formula.lines else { return }
        for index in offsets {
            modelContext.delete(lines[index])
        }
        saveFormula()
    }
    
    private func scaleFormula(to targetWeight: Double) {
        let currentWeight = formula.totalFormulaWeight
        guard currentWeight > 0,
              let lines = formula.lines else { return }
        
        let factor = targetWeight / currentWeight
        
        for line in lines {
            line.amountGrams *= factor
        }
        
        formula.diluentWeight *= factor
        saveFormula()
    }
    
    private struct IngredientRow: View {
        let component: DilutedComponent
        
        var body: some View {
            HStack {
                Rectangle()
                    .fill(component.isOverLimit ? Color.red : Color.clear)
                    .frame(width: 4)
                    .cornerRadius(2)
                    .frame(height: 40)
                
                VStack(alignment: .leading) {
                    Text(component.chemical.name)
                        .font(.headline)
                    
                    if component.chemical.pyramidNote != "" {
                        Text(component.chemical.pyramidNote.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 4)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(component.originalAmount, specifier: "%.3f") g")
                        .font(.subheadline)
                    
                    if component.dilutionPercentage < 100 {
                        Text("\(component.dilutionPercentage, specifier: "%.1f")% sol.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let safeLimit = component.chemical.ifraSafeLimit {
                        Text("\(component.finalConcentration, specifier: "%.2f")% / \(safeLimit, specifier: "%.1f")%")
                            .font(.caption2)
                            .foregroundColor(
                                component.isOverLimit ? .red : .secondary
                            )
                    } else {
                        Text("\(component.finalConcentration, specifier: "%.2f")%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .contentShape(Rectangle())
        }
    }
}
