//
//  ExpenseMyApp.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 06/05/26.
//

import SwiftUI
import SwiftData

@main
struct ExpenseMyApp: App {

    var body: some Scene {

        WindowGroup {

            HomeView()
                .onAppear {

                    importPendingTransactions()
                }
        }
        .modelContainer(for: Transaction.self)
    }

    // MARK: - Import Pending Transactions

    @MainActor
    private func importPendingTransactions() {

        let pending =
        SharedDataManager.getPendingDTOs()

        guard !pending.isEmpty else {
            return
        }

        do {

            let container =
            try ModelContainer(
                for: Transaction.self
            )

            let context =
            ModelContext(container)

            for dto in pending {

                let transaction =
                dto.toTransaction()

                context.insert(transaction)
            }

            try context.save()

            SharedDataManager
                .clearPendingTransactions()

        } catch {

            print(
                "Import error: \(error)"
            )
        }
    }
}
