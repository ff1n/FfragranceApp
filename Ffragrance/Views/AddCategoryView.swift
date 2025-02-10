//
//  AddCategoryView.swift
//  Ffragrance
//
//  Created by Ffinian Elliott on 13/01/2025.
//


import SwiftUI

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var color: Color = .gray

    var body: some View {
        NavigationStack {
            Form {
                TextField("Category Name", text: $name)
                ColorPicker("Category Color", selection: $color)
            }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newCategory = Category(name: name, color: color)
                        modelContext.insert(newCategory)
                        do {
                            try modelContext.save() // Explicitly save
                            dismiss()
                        } catch {
                            print("Error saving category: \(error)")
                        }
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
