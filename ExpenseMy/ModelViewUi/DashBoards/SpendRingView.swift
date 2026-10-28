
import SwiftUI
import Charts

struct SpendRingView: View {

    let data: [(category: Category, total: Double)]

    private func color(
        for category: Category
    ) -> Color {

        switch category {

        case .food:
            return Color(hex: "#FF6B6B")

        case .transport:
            return Color(hex: "#4ECDC4")

        case .recharge:
            return Color(hex: "#A29BFE")

        case .shopping:
            return Color(hex: "#FFD93D")

        case .entertainment:
            return Color(hex: "#6C5CE7")

        case .healthcare:
            return Color(hex: "#00B894")

        case .rent:
            return Color(hex: "#E17055")

        case .uncategorized:
            return Color(hex: "#636E72")
        }
    }

    private var totalSpent: Double {

        data.reduce(0) {
            $0 + $1.total
        }
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            // Header
            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Where's your 💸 going?")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Spending by category")
                        .font(.caption)
                        .foregroundStyle(
                            .white.opacity(0.5)
                        )
                }

                Spacer()
            }

            if data.isEmpty {

                // Empty state
                VStack(spacing: 14) {

                    ZStack {

                        Circle()
                            .stroke(
                                Color.white.opacity(0.08),
                                lineWidth: 12
                            )
                            .frame(
                                width: 110,
                                height: 110
                            )

                        Circle()
                            .stroke(
                                Color.purple.opacity(0.3),
                                lineWidth: 12
                            )
                            .frame(
                                width: 110,
                                height: 110
                            )
                            .rotationEffect(
                                .degrees(-90)
                            )
                            .opacity(0.4)

                        Image(systemName: "chart.pie")
                            .font(
                                .system(size: 28)
                            )
                            .foregroundStyle(
                                .white.opacity(0.3)
                            )
                    }

                    Text("No data yet")
                        .font(.subheadline)
                        .foregroundStyle(
                            .white.opacity(0.4)
                        )
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: 160
                )

            } else {

                HStack(
                    alignment: .center,
                    spacing: 24
                ) {

                    // Donut chart
                    ZStack {

                        Chart(
                            data,
                            id: \.category
                        ) { item in

                            SectorMark(
                                angle: .value(
                                    "Amount",
                                    item.total
                                ),
                                innerRadius: .ratio(0.62),
                                angularInset: 3
                            )
                            .foregroundStyle(
                                color(
                                    for: item.category
                                )
                            )
                            .cornerRadius(6)
                        }
                        .frame(
                            width: 140,
                            height: 140
                        )

                        // Center
                        VStack(spacing: 3) {

                            Text("Total")
                                .font(.caption2)
                                .foregroundStyle(
                                    .white.opacity(0.5)
                                )

                            Text(
                                "₹\(Int(totalSpent))"
                            )
                            .font(
                                .system(
                                    size: 15,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(.white)
                        }
                    }

                    // Legend
                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {

                        ForEach(
                            data.prefix(5),
                            id: \.category
                        ) { item in

                            let categoryName =
                            item.category.rawValue
                                .components(
                                    separatedBy: " "
                                )
                                .first ?? ""

                            let percentage =
                            Int(
                                (item.total /
                                 max(totalSpent, 1)
                                ) * 100
                            )

                            HStack(spacing: 8) {

                                RoundedRectangle(
                                    cornerRadius: 3
                                )
                                .fill(
                                    color(
                                        for: item.category
                                    )
                                )
                                .frame(
                                    width: 10,
                                    height: 10
                                )

                                Text(
                                    item.category.emoji
                                    + " "
                                    + categoryName
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .white.opacity(0.8)
                                )
                                .lineLimit(1)

                                Spacer()

                                Text(
                                    "\(percentage)%"
                                )
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    color(
                                        for: item.category
                                    )
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Bottom amount row
                if data.count > 0 {

                    Divider()
                        .background(
                            Color.white.opacity(0.08)
                        )

                    HStack {

                        ForEach(
                            data.prefix(3),
                            id: \.category
                        ) { item in

                            VStack(spacing: 4) {

                                Text(
                                    item.category.emoji
                                )
                                .font(.title3)

                                Text(
                                    "₹\(Int(item.total))"
                                )
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)

                            if item.category != data.prefix(3).last?.category {

                                Divider()
                                    .background(
                                        Color.white.opacity(0.08)
                                    )
                                    .frame(height: 30)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)

        .background(
            Color.white.opacity(0.05)
        )

        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )

        .overlay(
            RoundedRectangle(
                cornerRadius: 20
            )
            .stroke(
                Color.white.opacity(0.08),
                lineWidth: 1
            )
        )
    }
}

#Preview {

    ZStack {

        Color(hex: "#0D0B1E")
            .ignoresSafeArea()

        SpendRingView(
            data: [
                (
                    category: .food,
                    total: 4500
                ),
                (
                    category: .shopping,
                    total: 3200
                ),
                (
                    category: .transport,
                    total: 1500
                ),
                (
                    category: .recharge,
                    total: 800
                ),
                (
                    category: .entertainment,
                    total: 600
                )
            ]
        )
        .padding()
    }
}
