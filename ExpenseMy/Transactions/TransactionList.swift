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
    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]
    @Environment(\.modelContext) private var context

    @State private var selectedFilter: DateFilter = .month
    @State private var selectedCategory: Category? = nil

    var filteredTransactions: [Transaction] {
        let range = selectedFilter.dateRange
        return allTransactions.filter { txn in
            let inDateRange = txn.date >= range.start && txn.date < range.end
            let inCategory  = selectedCategory == nil || txn.category == selectedCategory
            return inDateRange && inCategory
        }
    }

    var groupedTransactions: [(key: String, value: [Transaction])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let grouped = Dictionary(grouping: filteredTransactions) {
            formatter.string(from: $0.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var totalSpent: Double {
        filteredTransactions
            .filter { $0.type == .debit }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ZStack {
            // Dark background
            LinearGradient(
                colors: [Color(hex: "#0D0B1E"), Color(hex: "#130D2E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Dot grid
            Canvas { context, size in
                let spacing: CGFloat = 28
                var x: CGFloat = 0
                while x < size.width {
                    var y: CGFloat = 0
                    while y < size.height {
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                            with: .color(.white.opacity(0.06))
                        )
                        y += spacing
                    }
                    x += spacing
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: — Title
                HStack {
                    Text("Transactions")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Spacer()
                    // Total badge
                    if !filteredTransactions.isEmpty {
                        Text("₹\(Int(totalSpent))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.25))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // MARK: — Date Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DateFilter.allCases, id: \.self) { filter in
                            DarkFilterPill(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }

                // MARK: — Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        DarkFilterPill(title: "All ✦", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(Category.allCases, id: \.self) { cat in
                            DarkFilterPill(
                                title: "\(cat.emoji) \(cat.rawValue.components(separatedBy: " ").first ?? "")",
                                isSelected: selectedCategory == cat
                            ) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }

                // MARK: — Summary strip
                HStack {
                    Text("\(filteredTransactions.count) transactions")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("Spent: ₹\(Int(totalSpent))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "#FF6B6B"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04))

                // MARK: — List or Empty
                if filteredTransactions.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("🔍")
                            .font(.system(size: 50))
                        Text("Nothing found")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Try changing the filter")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12, pinnedViews: .sectionHeaders) {
                            ForEach(groupedTransactions, id: \.key) { group in
                                Section {
                                    VStack(spacing: 0) {
                                        ForEach(group.value) { txn in
                                            NavigationLink {
                                                TransactionDetailView(transaction: txn)
                                            } label: {
                                                DarkTransactionRowFull(transaction: txn)
                                            }
                                            .buttonStyle(.plain)

                                            if txn.id != group.value.last?.id {
                                                Divider()
                                                    .background(Color.white.opacity(0.07))
                                                    .padding(.leading, 68)
                                            }
                                        }
                                    }
                                    .background(Color.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                                    )
                                } header: {
                                    HStack {
                                        Text(group.key)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white.opacity(0.5))
                                            .textCase(.uppercase)
                                        Spacer()
                                        Text("₹\(Int(group.value.filter { $0.type == .debit }.reduce(0) { $0 + $1.amount }))")
                                            .font(.caption2)
                                            .foregroundStyle(Color(hex: "#FF6B6B").opacity(0.8))
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 4)
                                    .background(Color.clear)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func deleteTransactions(from group: [Transaction], at offsets: IndexSet) {
        for index in offsets {
            context.delete(group[index])
        }
    }
}

// MARK: — Dark Filter Pill
struct DarkFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected
                    ? Color.purple
                    : Color.white.opacity(0.07)
                )
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected
                            ? Color.clear
                            : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                )
        }
    }
}

// MARK: — Dark Transaction Row (full, for list)
struct DarkTransactionRowFull: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        transaction.type == .debit
                        ? Color.red.opacity(0.15)
                        : Color.green.opacity(0.15)
                    )
                    .frame(width: 46, height: 46)
                Text(transaction.category.emoji)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(transaction.category.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                    Text("·")
                        .foregroundStyle(.white.opacity(0.3))
                    Text(transaction.bank)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.type == .debit ? "-" : "+")₹\(Int(transaction.amount))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        transaction.type == .debit
                        ? Color(hex: "#FF6B6B")
                        : Color(hex: "#55EFC4")
                    )

                Text(transaction.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

#Preview {
    TransactionListView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
