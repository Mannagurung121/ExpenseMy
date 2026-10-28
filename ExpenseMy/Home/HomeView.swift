import SwiftUI
import SwiftData

struct HomeView: View {
    var body: some View {
        mainTabView
    }

    private var mainTabView: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "chart.pie.fill")
                }

            NavigationStack {
                TransactionListView()
            }
            .tabItem {
                Label("Transactions", systemImage: "list.bullet")
            }

            AddTransactionView()
                .tabItem {
                    Label("Add SMS", systemImage: "plus.circle.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
        }
        .tint(.purple)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
