//
//  DashboardViewModel.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 07/05/26.
//

import Foundation
import SwiftData
import Observation

@Observable
final class DashboardViewModel {
    var selectedFilter: DateFilter = .month

    // Inject transactions from outside (from @Query)
    func filteredTransactions(_ all: [Transaction]) -> [Transaction] {
        let range = selectedFilter.dateRange
        return all.filter { $0.date >= range.start && $0.date < range.end }
    }

    func totalSpent(_ transactions: [Transaction]) -> Double {
        transactions
            .filter { $0.type == .debit }
            .reduce(0) { $0 + $1.amount }
    }

    func totalReceived(_ transactions: [Transaction]) -> Double {
        transactions
            .filter { $0.type == .credit }
            .reduce(0) { $0 + $1.amount }
    }

    func categoryTotals(_ transactions: [Transaction]) -> [(category: Category, total: Double)] {
        let debits = transactions.filter { $0.type == .debit }
        let grouped = Dictionary(grouping: debits) { $0.category }
        return grouped
            .map { (category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }

    func topCategory(_ transactions: [Transaction]) -> Category? {
        categoryTotals(transactions).first?.category
    }

    func transactionCount(_ transactions: [Transaction]) -> Int {
        transactions.filter { $0.type == .debit }.count
    }

    func avgPerDay(_ transactions: [Transaction]) -> Double {
        let debits = transactions.filter { $0.type == .debit }
        guard !debits.isEmpty else { return 0 }

        let range = selectedFilter.dateRange
        let days = max(1, Calendar.current.dateComponents([.day], from: range.start, to: range.end).day ?? 1)
        return totalSpent(transactions) / Double(days)
    }

    // Last 6 months data for bar chart
    func last6MonthsData(_ all: [Transaction]) -> [(month: String, amount: Double)] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        return (0..<6).reversed().compactMap { offset -> (month: String, amount: Double)? in
            guard let date = cal.date(byAdding: .month, value: -offset, to: Date()),
                  let start = cal.date(from: cal.dateComponents([.year, .month], from: date)),
                  let end = cal.date(byAdding: .month, value: 1, to: start) else { return nil }

            let total = all
                .filter { $0.type == .debit && $0.date >= start && $0.date < end }
                .reduce(0) { $0 + $1.amount }

            return (month: formatter.string(from: date), amount: total)
        }
    }
}

