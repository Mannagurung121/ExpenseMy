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
        .padding(.vertical, 4)
    }
}

// MARK: - UI Components

extension TransactionRow {

    private var categoryIcon: some View {

        ZStack {

            Circle()
                .fill(
                    transaction.type == .debit
                    ? Color.red.opacity(0.12)
                    : Color.green.opacity(0.12)
                )
                .frame(width: 44, height: 44)

            Text(transaction.category.emoji)
                .font(.title3)
        }
    }

    private var merchantSection: some View {

        VStack(alignment: .leading,
               spacing: 3) {

            Text(transaction.merchant)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Text(transaction.category.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var amountSection: some View {

        VStack(alignment: .trailing,
               spacing: 3) {

            Text(
                "\(transaction.type == .debit ? "-" : "+")₹\(transaction.amount, specifier: "%.0f")"
            )
            .fontWeight(.semibold)
            .foregroundStyle(
                transaction.type == .debit
                ? .red
                : .green
            )

            Text(transaction.bank)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {

    TransactionRow(
        transaction: Transaction.preview
    )
    .padding()
}
