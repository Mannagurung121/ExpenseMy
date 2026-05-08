//
//  SpendRingView.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 07/05/26.
//



import SwiftUI
import SwiftUI
import Charts

struct SpendRingView: View {
    let data: [(category: Category, total: Double)]

    private func color(for category: Category) -> Color {
        switch category {
        case .food:          return Color(hex: "#FF6B6B")
        case .transport:     return Color(hex: "#4ECDC4")
        case .recharge:      return Color(hex: "#A8E6CF")
        case .shopping:      return Color(hex: "#FFD93D")
        case .entertainment: return Color(hex: "#6C5CE7")
        case .healthcare:    return Color(hex: "#00B894")
        case .rent:          return Color(hex: "#E17055")
        case .uncategorized: return Color(hex: "#B2BEC3")
        }
    }

    private var totalSpent: Double {
        data.reduce(0) { $0 + $1.total }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Where's your money going?")
                .font(.headline)
                .fontWeight(.semibold)

            if data.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No data yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                HStack(alignment: .center, spacing: 20) {
                    // Donut chart
                    ZStack {
                        Chart(data, id: \.category) { item in
                            SectorMark(
                                angle: .value("Amount", item.total),
                                innerRadius: .ratio(0.65),
                                angularInset: 3
                            )
                            .foregroundStyle(color(for: item.category))
                            .cornerRadius(6)
                        }
                        .frame(width: 150, height: 150)

                        // Center text
                        VStack(spacing: 2) {
                            Text("Total")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("₹\(Int(totalSpent))")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }

                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(data.prefix(5), id: \.category) { item in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(color(for: item.category))
                                    .frame(width: 10, height: 10)

                                Text(item.category.emoji + " " +
                                     (item.category.rawValue
                                        .components(separatedBy: " ").first ?? ""))
                                    .font(.caption)
                                    .lineLimit(1)

                                Spacer()

                                let pct = Int((item.total / totalSpent) * 100)
                                Text("\(pct)%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(18)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
// MARK: - Preview

#Preview {

    SpendRingView(
        data: [
            (.food, 4500),
            (.shopping, 3200),
            (.transport, 1500),
            (.recharge, 800)
        ]
    )
    .padding()
}
