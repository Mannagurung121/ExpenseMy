//
//  TransactionViewModel.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 07/05/26.
//

import Foundation
import SwiftData

@Observable
final class TransactionViewModel {
    var searchText: String = ""
    var selectedCategory: Category? = nil
    var selectedType: TransactionType? = nil   // nil = both
    var sortOrder: SortOrder = .dateDesc

    enum SortOrder: String, CaseIterable {
        case dateDesc  = "Newest first"
        case dateAsc   = "Oldest first"
        case amountDesc = "Highest amount"
        case amountAsc  = "Lowest amount"
    }

    func filtered(_ transactions: [Transaction], dateFilter: DateFilter) -> [Transaction] {
        let range = dateFilter.dateRange

        var result = transactions.filter { txn in
            // Date filter
            guard txn.date >= range.start && txn.date < range.end else { return false }

            // Category filter
            if let cat = selectedCategory, txn.category != cat { return false }

            // Type filter
            if let type = selectedType, txn.type != type { return false }

            // Search
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let matchesMerchant  = txn.merchant.lowercased().contains(query)
                let matchesCategory  = txn.category.rawValue.lowercased().contains(query)
                let matchesBank      = txn.bank.lowercased().contains(query)
                if !matchesMerchant && !matchesCategory && !matchesBank { return false }
            }
            return true
        }

        // Sort
        switch sortOrder {
        case .dateDesc:   result.sort { $0.date > $1.date }
        case .dateAsc:    result.sort { $0.date < $1.date }
        case .amountDesc: result.sort { $0.amount > $1.amount }
        case .amountAsc:  result.sort { $0.amount < $1.amount }
        }

        return result
    }

    func groupedByDate(_ transactions: [Transaction]) -> [(key: String, value: [Transaction])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let grouped = Dictionary(grouping: transactions) { txn in
            formatter.string(from: txn.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    func delete(_ transaction: Transaction, context: ModelContext) {
        context.delete(transaction)
        try? context.save()
    }

    func updateCategory(_ transaction: Transaction, to category: Category, context: ModelContext) {
        transaction.category = category
        try? context.save()
    }
}
