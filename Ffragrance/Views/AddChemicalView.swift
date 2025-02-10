//
//  AddChemicalView.swift
//  Ffragrance
//
//  Created by Ffinian Elliott on 13/01/2025.
//

import SwiftUI
import Foundation

struct AddChemicalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var chemical = AromaChemical()

    var body: some View {
        NavigationStack {
            ChemicalDetailView(chemical: chemical)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            modelContext.insert(chemical)
                            do {
                                try modelContext.save() // Explicitly save
                                dismiss()
                            } catch {
                                print("Error saving chemical: \(error)")
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
