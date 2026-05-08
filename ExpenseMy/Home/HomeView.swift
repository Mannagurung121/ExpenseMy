//
//  HomeView.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 06/05/26.
//

import SwiftUI

struct HomeView: View {

    var body: some View {

        TabView {

            DashboardView()
                .tabItem {

                    Label(
                        "Dashboard",
                        systemImage: "chart.pie.fill"
                    )
                }

            TransactionListView()
                .tabItem {

                    Label(
                        "Transactions",
                        systemImage: "list.bullet"
                    )
                }

            AddTransactionView()
                .tabItem {

                    Label(
                        "Add SMS",
                        systemImage: "plus.circle.fill"
                    )
                }
        }
    }
}

#Preview {

    HomeView()
}
