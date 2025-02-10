//
//  TagManagerView.swift
//  Ffragrance
//
//  Created by Ffinian Elliott on 14/01/2025.
//

import SwiftUI
import SwiftData

struct TagManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Tag.name, order: .forward)])
    private var tags: [Tag]
    
    @State private var showAddTag = false
    @State private var newTagName = ""
    @State private var selectedColor: Color = .blue
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(tags) { tag in
                    HStack {
                        Circle()
                            .fill(tag.color)
                            .frame(width: 20, height: 20)
                        
                        Text(tag.name)
                        
                        Spacer()
                        
                        Text("\(tag.chemicals?.count ?? 0) items")
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete(perform: deleteTags)
            }
            .navigationTitle("Manage Tags")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddTag.toggle() }) {
                        Label("Add Tag", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddTag) {
                NavigationStack {
                    Form {
                        TextField("Tag Name", text: $newTagName)
                        
                        ColorPicker("Tag Color", selection: $selectedColor)
                    }
                    .navigationTitle("New Tag")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                let tag = Tag(name: newTagName, color: selectedColor)
                                modelContext.insert(tag)
                                newTagName = ""
                                selectedColor = .blue
                                showAddTag = false
                            }
                            .disabled(newTagName.isEmpty)
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel", role: .cancel) {
                                showAddTag = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tags[index])
        }
    }
}
