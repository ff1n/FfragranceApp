//
//  CategoryView.swift
//  Ffragrance
//
//  Created by Ffinian Elliott on 13/01/2025.
//

import SwiftUI
import Foundation
import SwiftData

struct CategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Category.name, order: .forward)])
    private var categories: [Category]

    @State private var showAddCategory = false
    @State private var showDeleteAlert = false
    @State private var categoryToDelete: Category?

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    HStack {
                        Circle()
                            .fill(category.color)
                            .frame(width: 20, height: 20)
                        Text(category.name)
                            .font(.headline)
                    }
                }
                .onDelete(perform: attemptDeleteCategories)
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddCategory.toggle() }) {
                        Label("Add Category", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategoryView()
            }
            .alert("Can't Delete Category", isPresented: $showDeleteAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("\(categoryToDelete?.name ?? "This category") contains ingredients and can't be deleted.")
            }
        }
    }

    private func attemptDeleteCategories(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        let category = categories[index]
        
        if category.chemicals?.isEmpty ?? true {
            deleteCategory(category)
        } else {
            categoryToDelete = category
            showDeleteAlert = true
        }
    }
    
    private func deleteCategory(_ category: Category) {
        modelContext.delete(category)
    }
}
