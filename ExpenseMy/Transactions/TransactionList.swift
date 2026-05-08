//
//  TransactionList.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 06/05/26.
//

//
//  TransactionListView.swift
//  ExpenseMy
//

import SwiftUI
import SwiftData

struct TransactionListView: View {

    @Query(
        sort: \Transaction.date,
        order: .reverse
    )
    private var allTransactions: [Transaction]

    @Environment(\.modelContext) private var context

    @State private var selectedFilter: DateFilter = .month
    @State private var selectedCategory: Category? = nil

    // MARK: - Filtered Transactions

    var filteredTransactions: [Transaction] {

        let range = selectedFilter.dateRange

        return allTransactions.filter { txn in

            let inDateRange =
            txn.date >= range.start &&
            txn.date < range.end

            let inCategory =
            selectedCategory == nil ||
            txn.category == selectedCategory

            return inDateRange && inCategory
        }
    }

    // MARK: - Grouped Transactions

    var groupedTransactions: [
        (key: String, value: [Transaction])
    ] {

        let formatter = DateFormatter()

        formatter.dateStyle = .medium

        let grouped = Dictionary(
            grouping: filteredTransactions
        ) { txn in

            formatter.string(from: txn.date)
        }

        return grouped.sorted {
            $0.key > $1.key
        }
    }

    // MARK: - Total Spent

    var totalSpent: Double {

        filteredTransactions
            .filter { $0.type == .debit }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                // MARK: Date Filters

                ScrollView(
                    .horizontal,
                    showsIndicators: false
                ) {

                    HStack(spacing: 8) {

                        ForEach(
                            DateFilter.allCases,
                            id: \.self
                        ) { filter in

                            FilterPill(
                                title: filter.rawValue,

                                isSelected:
                                    selectedFilter == filter
                            ) {

                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                // MARK: Category Filters

                ScrollView(
                    .horizontal,
                    showsIndicators: false
                ) {

                    HStack(spacing: 8) {

                        FilterPill(
                            title: "All",

                            isSelected:
                                selectedCategory == nil
                        ) {

                            selectedCategory = nil
                        }

                        ForEach(
                            Category.allCases,
                            id: \.self
                        ) { cat in

                            FilterPill(
                                title:
                                    "\(cat.emoji) \(cat.rawValue)",

                                isSelected:
                                    selectedCategory == cat
                            ) {

                                selectedCategory =
                                    selectedCategory == cat
                                    ? nil
                                    : cat
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }

                Divider()

                // MARK: Summary

                HStack {

                    Text(
                        "\(filteredTransactions.count) transactions"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Spacer()

                    Text(
                        "Total: ₹\(totalSpent, specifier: "%.0f")"
                    )
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))

                // MARK: Empty State

                if filteredTransactions.isEmpty {

                    Spacer()

                    VStack(spacing: 12) {

                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)

                        Text("No transactions found")
                            .fontWeight(.medium)

                        Text(
                            "Try changing the date or category filter"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                } else {

                    // MARK: Transaction List

                    List {

                        ForEach(
                            groupedTransactions,
                            id: \.key
                        ) { group in

                            Section(group.key) {

                                ForEach(group.value) { txn in

                                    TransactionRow(
                                        transaction: txn
                                    )
                                }
                                .onDelete { indexSet in

                                    deleteTransactions(
                                        from: group.value,
                                        at: indexSet
                                    )
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Transactions")
        }
    }

    // MARK: Delete

    private func deleteTransactions(
        from group: [Transaction],
        at offsets: IndexSet
    ) {

        for index in offsets {

            context.delete(group[index])
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected
                    ? Color.purple
                    : Color(.systemGray5)
                )
                .foregroundStyle(
                    isSelected
                    ? .white
                    : .primary
                )
                .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview {

    TransactionListView()
        .modelContainer(
            for: Transaction.self,
            inMemory: true
        )
}
