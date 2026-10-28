//
//  TransactionRow.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 06/05/26.
//
//
//  TransactionRow.swift
//  ExpenseMy
//

import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 14) {
            categoryIcon
            merchantSection
            Spacer()
            amountSection
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
}

extension TransactionRow {

    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(
                    transaction.type == .debit
                    ? Color.red.opacity(0.15)
                    : Color.green.opacity(0.15)
                )
                .frame(width: 46, height: 46)
                .overlay(
                    Circle()
                        .stroke(
                            transaction.type == .debit
                            ? Color.red.opacity(0.2)
                            : Color.green.opacity(0.2),
                            lineWidth: 1
                        )
                )
            Text(transaction.category.emoji)
                .font(.title3)
        }
    }

    private var merchantSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(transaction.merchant)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            HStack(spacing: 6) {
                Text(transaction.category.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("·")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(transaction.date.formatted(
                    .dateTime.day().month(.abbreviated)
                ))
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var amountSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(
                "\(transaction.type == .debit ? "-" : "+")₹\(transaction.amount, specifier: "%.0f")"
            )
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(
                transaction.type == .debit ? .red : .green
            )

            Text(transaction.bank)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#0D0B1E").ignoresSafeArea()
        VStack(spacing: 0) {
            ForEach(["Zomato", "Netflix", "Airtel"], id: \.self) { name in
                TransactionRow(transaction: Transaction(
                    amount: Double.random(in: 100...1500),
                    type: .debit,
                    merchant: name,
                    category: .food,
                    bank: "Kotak",
                    date: Date(),
                    rawSMS: ""
                ))
                .padding(.horizontal, 16)
                Divider().padding(.leading, 60)
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }
}
