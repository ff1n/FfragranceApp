import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Existing query for AromaChemical
    @Query(sort: [SortDescriptor(\AromaChemical.name, order: .forward)])
    private var chemicals: [AromaChemical]
    
    // NEW: Query all FormulaLine objects, so we can see if any references a given chemical
    @Query(sort: [SortDescriptor(\FormulaLine.amountGrams)])
    private var formulaLines: [FormulaLine]
    
    // Existing UI state
    @State private var showAddChemical = false
    @State private var showTagManager = false
    @State private var searchText = ""
    @State private var sortByPyramidNote = true
    
    // NEW: UI state for the “in use” alert
    @State private var showInUseAlert = false
    @State private var inUseChemicalName = ""
    
    private let pyramidNoteOrder = ["top", "topmid", "mid", "midbase", "base"]
    
    var filteredChemicals: [AromaChemical] {
        guard !searchText.isEmpty else { return chemicals }
        return chemicals.filter { chemical in
            chemical.name.localizedCaseInsensitiveContains(searchText) ||
            chemical.casNumber.localizedCaseInsensitiveContains(searchText) ||
            chemical.category?.name.localizedCaseInsensitiveContains(searchText) == true ||
            (chemical.tags ?? []).contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) })
        }
    }

    
    var body: some View {
        NavigationStack {
            VStack {
                // Your existing search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                List {
                    if sortByPyramidNote {
                        ForEach(sortedPyramidNotes, id: \.self) { pyramidNote in
                            Section(header: Text(pyramidNote.capitalized)) {
                                ForEach(groupedChemicalsByPyramid[pyramidNote] ?? []) { chemical in
                                    ChemicalRow(chemical: chemical)
                                }
                            }
                        }
                    } else {
                        // The user can swipe to delete only in this section
                        ForEach(filteredChemicals.sorted(by: { $0.name < $1.name })) { chemical in
                            ChemicalRow(chemical: chemical)
                        }
                        .onDelete(perform: deleteChemicals)
                    }
                }
            }
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddChemical.toggle() }) {
                        Label("Add Chemical", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { sortByPyramidNote.toggle() }) {
                        Label("Sort: \(sortByPyramidNote ? "Pyramid Note" : "Name")",
                              systemImage: "arrow.up.arrow.down")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showTagManager.toggle() }) {
                        Label("Manage Tags", systemImage: "tag")
                    }
                }
            }
            // Sheets for “Add Chemical” and “Manage Tags”
            .sheet(isPresented: $showAddChemical) {
                AddChemicalView()
            }
            .sheet(isPresented: $showTagManager) {
                TagManagerView()
            }
            // Present an alert if the chemical is still in use
            .alert("Cannot Delete Chemical",
                   isPresented: $showInUseAlert,
                   actions: {
                       Button("OK", role: .cancel) { }
                   },
                   message: {
                       Text("\(inUseChemicalName) is used in one or more formulas and cannot be deleted.")
                   }
            )
        }
    }
    
    /// Modified delete function that checks for usage in any FormulaLine
    private func deleteChemicals(at offsets: IndexSet) {
        let sortedChemicals = filteredChemicals.sorted(by: { $0.name < $1.name })
        
        for index in offsets {
            let chemicalToDelete = sortedChemicals[index]
            
            // Check both direct relationships and formula lines
            let hasReferences = (chemicalToDelete.formulaLines?.isEmpty == false) ||
                              !formulaLines.filter { $0.chemical?.id == chemicalToDelete.id }.isEmpty
            
            if hasReferences {
                inUseChemicalName = chemicalToDelete.name
                showInUseAlert = true
            } else {
                modelContext.delete(chemicalToDelete)
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving after deletions: \(error)")
        }
    }
    private var groupedChemicalsByPyramid: [String: [AromaChemical]] {
        Dictionary(grouping: filteredChemicals, by: { $0.pyramidNote })
    }
    
    private var sortedPyramidNotes: [String] {
        pyramidNoteOrder.filter { groupedChemicalsByPyramid.keys.contains($0) }
    }
}

// The rest of your code is unchanged.
// ChemicalRow, TagView, SearchBar remain as before.

struct ChemicalRow: View {
    let chemical: AromaChemical
    
    var body: some View {
        NavigationLink(destination: ChemicalDetailView(chemical: chemical)) {
            HStack {
                if let category = chemical.category {
                    Rectangle()
                        .fill(category.color)
                        .frame(width: 4)
                        .cornerRadius(2)
                        .frame(height: 40)
                }
                
                VStack(alignment: .leading) {
                    Text(chemical.name)
                        .font(.headline)
                    
                    HStack {
                        Text("CAS: \(chemical.casNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let tags = chemical.tags, !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(tags) { tag in
                                        TagView(tag: tag)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.leading, 4)
            }
        }
    }
}

struct TagView: View {
    let tag: Tag
    
    var body: some View {
        Text(tag.name)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tag.color)
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search chemicals...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
