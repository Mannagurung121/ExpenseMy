//
//  MonthBarChart.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 07/05/26.
//

import SwiftUI
import Charts

struct MonthBarChart: View {
    let data: [(month: String, amount: Double)]
    @State private var selectedMonth: String? = nil

    private var maxAmount: Double {
        data.map(\.amount).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly spending")
                        .font(.headline)
                        .fontWeight(.semibold)
                    if let month = selectedMonth,
                       let entry = data.first(where: { $0.month == month }) {
                        Text("₹\(Int(entry.amount)) in \(month)")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    } else {
                        Text("Last 6 months")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            if data.allSatisfy({ $0.amount == 0 }) {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No data yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(data, id: \.month) { item in
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(
                        item.month == selectedMonth
                        ? Color.purple
                        : Color.purple.opacity(0.3)
                    )
                    .cornerRadius(8)
                }
                .frame(height: 160)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let month = value.as(String.self) {
                                Text(month)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                if let frame = proxy.plotFrame {
                                    let origin = geo[frame].origin
                                    let relX = location.x - origin.x
                                    if let month: String = proxy.value(atX: relX) {
                                        withAnimation(.spring(duration: 0.2)) {
                                            selectedMonth = selectedMonth == month ? nil : month
                                        }
                                    }
                                }
                            }
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {

    MonthBarChart(
        data: [
            ("Jan", 1200),
            ("Feb", 3400),
            ("Mar", 2800),
            ("Apr", 5100),
            ("May", 4200),
            ("Jun", 3900)
        ]
    )
    .padding()
}
