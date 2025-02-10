import SwiftUI
import SwiftData
import CloudKit
import CoreData

@MainActor
class SyncMonitor: ObservableObject {
    @Published var syncStatus: String = "Checking iCloud status..."
    @Published var showingSyncAlert = false
    @Published var syncError: Error?
    @Published var showingConflictResolver = false
    @Published var conflictedRecords: [CKRecord]?
    
    init() {
        setupNotifications()
        checkCloudKitStatus() // Check status immediately on init
    }
    
    private func setupNotifications() {
        // Listen for CloudKit account status changes
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkCloudKitStatus()
        }
        
        // Monitor sync status through CoreData/SwiftData
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSyncChange()
        }
    }
    
    private func checkCloudKitStatus() {
        Task {
            do {
                let status = try await CKContainer.default().accountStatus()
                await MainActor.run {
                    switch status {
                    case .available:
                        self.syncStatus = "iCloud Account Available"
                    case .noAccount:
                        self.syncStatus = "No iCloud Account"
                    case .restricted:
                        self.syncStatus = "iCloud Access Restricted"
                    case .couldNotDetermine:
                        self.syncStatus = "Could not determine iCloud status"
                    case .temporarilyUnavailable:
                        self.syncStatus = "iCloud temporarily unavailable"
                    @unknown default:
                        self.syncStatus = "Unknown iCloud status"
                    }
                }
            } catch {
                await handleSyncError(error)
            }
        }
    }
    
    private func handleSyncChange() {
        syncStatus = "Syncing changes..."
        
        // After a delay, update to completed status
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if syncStatus == "Syncing changes..." {
                syncStatus = "Changes synced"
                
                // Reset to available after another delay
                try? await Task.sleep(for: .seconds(2))
                if syncStatus == "Changes synced" {
                    syncStatus = "iCloud Account Available"
                }
            }
        }
    }
    
    private func handleSyncError(_ error: Error) {
        syncError = error
        showingSyncAlert = true
        
        if let ckError = error as? CKError {
            switch ckError.code {
            case .serverRecordChanged:
                // Handle conflict
                if let serverRecord = ckError.serverRecord {
                    conflictedRecords = [serverRecord]
                    showingConflictResolver = true
                }
            case .notAuthenticated:
                syncStatus = "Please sign in to iCloud in Settings"
            case .quotaExceeded:
                syncStatus = "iCloud storage quota exceeded"
            case .networkFailure:
                syncStatus = "Network connection failed"
            default:
                syncStatus = "Sync error: \(error.localizedDescription)"
            }
        }
    }
}

// Add extension for the notification name
extension Notification.Name {
    static let NSPersistentStoreRemoteChange = Notification.Name("NSPersistentStoreRemoteChangeNotification")
}
