//
//  DashboardView.swift
//  ExpenseMy
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {

    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]

    @State private var isProfile: Bool = false
    @State private var viewModel = DashboardViewModel()

    private var transactions: [Transaction] {
        viewModel.filteredTransactions(allTransactions)
    }

    var body: some View {

        ZStack {

            // MARK: Background

            LinearGradient(
                colors: [
                    Color(hex: "#0D0B1E"),
                    Color(hex: "#130D2E"),
                    Color(hex: "#0A0818")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // MARK: Dot Grid

            Canvas { context, size in

                let spacing: CGFloat = 28

                var x: CGFloat = 0

                while x < size.width {

                    var y: CGFloat = 0

                    while y < size.height {

                        context.fill(
                            Path(
                                ellipseIn: CGRect(
                                    x: x,
                                    y: y,
                                    width: 1.5,
                                    height: 1.5
                                )
                            ),
                            with: .color(.white.opacity(0.07))
                        )

                        y += spacing
                    }

                    x += spacing
                }
            }
            .ignoresSafeArea()

            // MARK: Glow Blobs

            GeometryReader { geo in

                Circle()
                    .fill(Color.purple.opacity(0.18))
                    .frame(width: 320)
                    .offset(x: geo.size.width - 100, y: -100)
                    .blur(radius: 80)

                Circle()
                    .fill(Color.indigo.opacity(0.14))
                    .frame(width: 280)
                    .offset(x: -80, y: geo.size.height * 0.45)
                    .blur(radius: 70)

                Circle()
                    .fill(Color(hex: "#6C5CE7").opacity(0.10))
                    .frame(width: 200)
                    .offset(
                        x: geo.size.width * 0.3,
                        y: geo.size.height * 0.7
                    )
                    .blur(radius: 60)
            }
            .ignoresSafeArea()

            // MARK: Main Content

            ScrollView(showsIndicators: false) {

                VStack(spacing: 20) {

                    // MARK: Header

                    HStack {

                        VStack(alignment: .leading, spacing: 4) {

                            Text("ExpenseMy")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)

                            Text("Track. Save. Flex. 💜")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()

                        NavigationLink(
                            destination: ProfileView()
                        ) {

                            ZStack {

                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .indigo],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                    .shadow(
                                        color: .purple.opacity(0.5),
                                        radius: 8
                                    )

                                if UserManager.shared.initials.isEmpty {

                                    Text("💸")
                                        .font(.title3)

                                } else {

                                    Text(UserManager.shared.initials)
                                        .font(
                                            .system(
                                                size: 15,
                                                weight: .bold
                                            )
                                        )
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // MARK: Filter Pills

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
                                            : Color.white.opacity(0.08)
                                        )
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // MARK: Hero Card

                    ZStack {

                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#7B2FBE"),
                                        Color(hex: "#4A1A8C")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(alignment: .leading, spacing: 16) {

                            HStack {

                                Text(
                                    UserManager.shared.userName.isEmpty
                                    ? "Total spent"
                                    : "Hey, \(UserManager.shared.userName.components(separatedBy: " ").first ?? "") 👋"
                                )
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))

                                Spacer()
                            }

                            Text("₹\(Int(viewModel.totalSpent(transactions)))")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundStyle(.white)

                            HStack {

                                Text("\(viewModel.transactionCount(transactions)) transactions")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))

                                Spacer()
                            }
                        }
                        .padding(20)
                    }
                    .frame(height: 178)
                    .padding(.horizontal, 20)

                    // MARK: Stats Grid

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 12
                    ) {

                        DarkStatCard(
                            emoji: "🔥",
                            title: "Top category",
                            value: viewModel.topCategory(transactions)?.rawValue ?? "None",
                            sub: "Most used",
                            accent: .red
                        )

                        DarkStatCard(
                            emoji: "📊",
                            title: "Avg / day",
                            value: "₹\(Int(viewModel.avgPerDay(transactions)))",
                            sub: viewModel.selectedFilter.rawValue,
                            accent: .cyan
                        )

                        DarkStatCard(
                            emoji: "💳",
                            title: "Transactions",
                            value: "\(viewModel.transactionCount(transactions))",
                            sub: "All entries",
                            accent: .purple
                        )

                        DarkStatCard(
                            emoji: "✨",
                            title: "Insights",
                            value: "Smart",
                            sub: "AI powered",
                            accent: .green
                        )
                    }
                    .padding(.horizontal, 20)

                    // MARK: Charts

                    DarkChartCard {

                        SpendRingView(
                            data: viewModel.categoryTotals(transactions)
                        )
                    }
                    .padding(.horizontal, 20)

                    DarkChartCard {

                        MonthBarChart(
                            data: viewModel.last6MonthsData(allTransactions)
                        )
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 30)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: Dark Chart Card

struct DarkChartCard<Content: View>: View {

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {

        self.content = content
    }

    var body: some View {

        content()
            .padding(18)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

// MARK: Dark Stat Card

struct DarkStatCard: View {

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
            }

            Spacer()

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))

            Text(sub)
                .font(.caption2)
                .foregroundStyle(accent)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {

    NavigationStack {

        DashboardView()
            .modelContainer(
                for: Transaction.self,
                inMemory: true
            )
    }
}
