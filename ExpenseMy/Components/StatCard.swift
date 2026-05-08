//
//  StatCard.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 07/05/26.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String          // SF Symbol name
    let iconColor: Color

    init(title: String,
         value: String,
         subtitle: String? = nil,
         icon: String,
         iconColor: Color) {
        self.title     = title
        self.value     = value
        self.subtitle  = subtitle
        self.icon      = icon
        self.iconColor = iconColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            Spacer()

            // Value
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Title
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Optional subtitle
            if let sub = subtitle {
                Text(sub)
                    .font(.caption2)
                    .foregroundStyle(iconColor)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// Preview helper
#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        StatCard(title: "Total spent", value: "₹4,230",
                 subtitle: "This month",
                 icon: "indianrupeesign.circle.fill", iconColor: .red)

        StatCard(title: "Transactions", value: "12",
                 subtitle: "Debits only",
                 icon: "arrow.up.arrow.down.circle.fill", iconColor: .purple)

        StatCard(title: "Top category", value: "🍔 Food",
                 subtitle: "₹1,840 spent",
                 icon: "star.circle.fill", iconColor: .orange)

        StatCard(title: "Avg per day", value: "₹141",
                 subtitle: "This month",
                 icon: "calendar.circle.fill", iconColor: .blue)
    }
    .padding()
}
