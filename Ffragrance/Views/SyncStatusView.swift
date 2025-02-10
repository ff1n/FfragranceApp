//
//  SyncStatusView.swift
//  Ffragrance
//
//  Created by Ffinian Elliott on 18/01/2025.
//


import SwiftUI
import CloudKit

struct SyncStatusView: View {
    @StateObject private var syncMonitor = SyncMonitor()
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "icloud")
                    .foregroundColor(statusColor)
                Text(syncMonitor.syncStatus)
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.top, 2)
        }
        .alert("Sync Error",
               isPresented: $syncMonitor.showingSyncAlert,
               presenting: syncMonitor.syncError) { error in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
        }
        .sheet(isPresented: $syncMonitor.showingConflictResolver) {
            ConflictResolverView(records: syncMonitor.conflictedRecords ?? [])
        }
    }
    
    private var statusColor: Color {
        switch syncMonitor.syncStatus {
        case "iCloud Account Available":
            return .green
        case "Changes synced":
            return .green
        case "Syncing changes...":
            return .blue
        case _ where syncMonitor.syncStatus.contains("error"):
            return .red
        default:
            return .orange
        }
    }
}

struct ConflictResolverView: View {
    @Environment(\.dismiss) private var dismiss
    let records: [CKRecord]
    
    var body: some View {
        NavigationStack {
            List(records, id: \.recordID) { record in
                VStack(alignment: .leading) {
                    Text("Conflict detected")
                        .font(.headline)
                    
                    Text("Local version modified: \(record.modificationDate?.description ?? "Unknown")")
                        .font(.subheadline)
                    Text("Server version modified: \(record.modificationDate?.description ?? "Unknown")")
                        .font(.subheadline)
                    
                    HStack {
                        Button("Keep Local") {
                            // Handle keeping local version
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Keep Server") {
                            // Handle keeping server version
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Merge Changes") {
                            // Handle merging both versions
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Resolve Conflict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SyncStatusView()
}