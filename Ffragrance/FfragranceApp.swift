import SwiftUI
import SwiftData

struct PrivacyPolicyView: View {
    @Binding var hasAcceptedPrivacyPolicy: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Privacy Policy")
                    .font(.title)
                    .bold()
                
                Text("Ffragrance takes your privacy seriously. Please review our privacy policy to understand how we handle your data.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Link("Read Privacy Policy",
                     destination: URL(string: "https://ffragrance-app.tiiny.site")!)
                    .padding()
                
                HStack(spacing: 20) {
                    Button(action: {
                        exit(0)
                    }) {
                        Text("Decline")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Button(action: {
                        UserDefaults.standard.set(true, forKey: "hasAcceptedPrivacyPolicy")
                        hasAcceptedPrivacyPolicy = true
                        dismiss()
                    }) {
                        Text("Accept")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .padding()
        }
    }
}

@main
struct FfragranceApp: App {
    @AppStorage("hasAcceptedPrivacyPolicy") private var hasAcceptedPrivacyPolicy = false
    let container: ModelContainer
    @StateObject private var syncMonitor = SyncMonitor()
    
    init() {
        do {
            let schema = Schema([
                AromaChemical.self,
                Category.self,
                Formula.self,
                FormulaLine.self,
                Tag.self
            ])
            
            // Create a configuration with CloudKit enabled
            let config = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private("iCloud.com.ffinian.Ffragrance")
            )
            
            // Initialize the container
            container = try ModelContainer(
                for: schema,
                configurations: [config]
            )
            
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                TabView {
                    InventoryView()
                        .tabItem {
                            Label("Inventory", systemImage: "list.bullet")
                        }
                    
                    NavigationStack {
                        FormulaListView()
                    }
                    .tabItem {
                        Label("Formulas", systemImage: "flask")
                    }
                    
                    CategoryView()
                        .tabItem {
                            Label("Categories", systemImage: "tag")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
                .modelContainer(container)
                .environmentObject(syncMonitor)
                
                .overlay(alignment: .top) {
                    SyncStatusView()
                        .environmentObject(syncMonitor)
                }
                
                // Show privacy policy overlay if not accepted
                if !hasAcceptedPrivacyPolicy {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    
                    PrivacyPolicyView(hasAcceptedPrivacyPolicy: $hasAcceptedPrivacyPolicy)
                        .transition(.opacity)
                }
            }
        }
    }
}
