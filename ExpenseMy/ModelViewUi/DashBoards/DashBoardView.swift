//
//  DashBoardView.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 06/05/26.
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]

    @State private var viewModel = DashboardViewModel()

    private var transactions: [Transaction] {
        viewModel.filteredTransactions(allTransactions)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground).ignoresSafeArea()

                // Decorative blobs
                GeometryReader { geo in
                    Circle()
                        .fill(Color.purple.opacity(0.12))
                        .frame(width: 300, height: 300)
                        .offset(x: geo.size.width - 120, y: -80)
                        .blur(radius: 60)

                    Circle()
                        .fill(Color.indigo.opacity(0.10))
                        .frame(width: 250, height: 250)
                        .offset(x: -60, y: geo.size.height * 0.4)
                        .blur(radius: 50)
                }
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // MARK: — Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SpendSense")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Track. Save. Flex. 💜")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            // Doodle avatar
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .indigo],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 42, height: 42)
                                Text("💸")
                                    .font(.title3)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // MARK: — Filter pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(DateFilter.allCases, id: \.self) { filter in
                                    Button {
                                        withAnimation(.spring(duration: 0.3)) {
                                            viewModel.selectedFilter = filter
                                        }
                                    } label: {
                                        Text(filter.rawValue)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                viewModel.selectedFilter == filter
                                                ? Color.purple
                                                : Color(.systemGray5)
                                            )
                                            .foregroundStyle(
                                                viewModel.selectedFilter == filter
                                                ? Color.white
                                                : Color.primary
                                            )
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // MARK: — Hero Total Card
                        ZStack {
                            // Doodle grid background
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.purple.opacity(0.9),
                                            Color.indigo.opacity(0.95)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            // Doodle circles decoration
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    .frame(width: 180, height: 180)
                                    .offset(x: 100, y: -30)
                                Circle()
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                    .frame(width: 120, height: 120)
                                    .offset(x: 120, y: 20)
                                Circle()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 80, height: 80)
                                    .offset(x: -110, y: 40)
                            }

                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Total spent")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                    Spacer()
                                    Text(viewModel.selectedFilter.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.15))
                                        .clipShape(Capsule())
                                        .foregroundStyle(.white)
                                }

                                Text("₹\(Int(viewModel.totalSpent(transactions)))")
                                    .font(.system(size: 44, weight: .bold))
                                    .foregroundStyle(.white)

                                HStack(spacing: 20) {
                                    // Debit
                                    HStack(spacing: 6) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.red.opacity(0.25))
                                                .frame(width: 28, height: 28)
                                            Image(systemName: "arrow.up")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.red.opacity(0.9))
                                        }
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("Spent")
                                                .font(.caption2)
                                                .foregroundStyle(.white.opacity(0.6))
                                            Text("₹\(Int(viewModel.totalSpent(transactions)))")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.white)
                                        }
                                    }

                                    // Credit
                                    HStack(spacing: 6) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.green.opacity(0.25))
                                                .frame(width: 28, height: 28)
                                            Image(systemName: "arrow.down")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.green.opacity(0.9))
                                        }
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("Received")
                                                .font(.caption2)
                                                .foregroundStyle(.white.opacity(0.6))
                                            Text("₹\(Int(viewModel.totalReceived(transactions)))")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.white)
                                        }
                                    }

                                    Spacer()

                                    Text("\(viewModel.transactionCount(transactions)) txns")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                            .padding(20)
                        }
                        .frame(height: 175)
                        .padding(.horizontal, 20)

                        // MARK: — Stat Cards 2x2
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 12
                        ) {
                            CoolStatCard(
                                emoji: "🔥",
                                title: "Biggest spend",
                                value: viewModel.topCategory(transactions).map {
                                    $0.emoji + " " + ($0.rawValue.components(separatedBy: " ").first ?? "")
                                } ?? "None",
                                sub: viewModel.categoryTotals(transactions).first.map { "₹\(Int($0.total))" } ?? "—",
                                accent: .orange
                            )

                            CoolStatCard(
                                emoji: "📊",
                                title: "Avg per day",
                                value: "₹\(Int(viewModel.avgPerDay(transactions)))",
                                sub: viewModel.selectedFilter.rawValue,
                                accent: .blue
                            )

                            CoolStatCard(
                                emoji: "💳",
                                title: "Transactions",
                                value: "\(viewModel.transactionCount(transactions))",
                                sub: "Debits only",
                                accent: .purple
                            )

                            CoolStatCard(
                                emoji: "✨",
                                title: "Saved vs last",
                                value: "—",
                                sub: "Coming soon",
                                accent: .green
                            )
                        }
                        .padding(.horizontal, 20)

                        // MARK: — Donut Chart
                        SpendRingView(data: viewModel.categoryTotals(transactions))
                            .padding(.horizontal, 20)

                        // MARK: — Bar Chart
                        MonthBarChart(data: viewModel.last6MonthsData(allTransactions))
                            .padding(.horizontal, 20)

                        // MARK: — Recent Transactions
                        if !transactions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Recent")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Spacer()
                                    NavigationLink {
                                        TransactionListView()
                                    } label: {
                                        Text("See all →")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.purple)
                                    }
                                }

                                VStack(spacing: 0) {
                                    ForEach(transactions.prefix(5)) { txn in
                                        NavigationLink {
                                            TransactionDetailView(transaction: txn)
                                        } label: {
                                            CoolTransactionRow(transaction: txn)
                                        }
                                        .foregroundStyle(.primary)
                                        .buttonStyle(.plain)

                                        if txn.id != transactions.prefix(5).last?.id {
                                            Divider()
                                                .padding(.leading, 56)
                                        }
                                    }
                                }
                                .padding(4)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // Empty state with doodle
                            VStack(spacing: 16) {
                                Text("🎨")
                                    .font(.system(size: 60))
                                Text("Nothing here yet!")
                                    .font(.headline)
                                Text("Add your first transaction from the\nAdd SMS tab 👇")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: — Cool Stat Card
struct CoolStatCard: View {
    let emoji: String
    let title: String
    let value: String
    let sub: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(emoji)
                    .font(.title3)
                Spacer()
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 8, height: 8)
            }

            Spacer()

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(sub)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(accent)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accent.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: — Cool Transaction Row
struct CoolTransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Category circle
            ZStack {
                Circle()
                    .fill(
                        transaction.type == .debit
                        ? Color.red.opacity(0.1)
                        : Color.green.opacity(0.1)
                    )
                    .frame(width: 44, height: 44)
                Text(transaction.category.emoji)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.merchant)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(transaction.category.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(transaction.date.formatted(.dateTime.day().month(.abbreviated)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(transaction.type == .debit ? "-" : "+")₹\(Int(transaction.amount))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(transaction.type == .debit ? .red : .green)
                Text(transaction.bank)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

#Preview {

    DashboardView()
        .modelContainer(
            for: Transaction.self,
            inMemory: true
        )
}
