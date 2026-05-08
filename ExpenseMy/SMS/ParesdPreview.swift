//
//  ParesdPreview.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 06/05/26.
//

import SwiftUI

struct ParsedPreviewCard: View {

    let transaction: Transaction

    let onSave: () -> Void
    let onDiscard: () -> Void

    var body: some View {

        VStack(alignment: .leading,
               spacing: 16) {

            HStack {

                Text("Parsed Result")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            Divider()

            Grid(alignment: .leading,
                 verticalSpacing: 10) {

                GridRow {

                    Text("Amount")
                        .foregroundStyle(.secondary)

                    Text(
                        "₹\(transaction.amount, specifier: "%.2f")"
                    )
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        transaction.type == .debit
                        ? .red
                        : .green
                    )
                }

                GridRow {

                    Text("Type")
                        .foregroundStyle(.secondary)

                    Text(
                        transaction.type == .debit
                        ? "Debit"
                        : "Credit"
                    )
                }

                GridRow {

                    Text("Merchant")
                        .foregroundStyle(.secondary)

                    Text(transaction.merchant)
                }

                GridRow {

                    Text("Category")
                        .foregroundStyle(.secondary)

                    Text(
                        "\(transaction.category.emoji) \(transaction.category.rawValue)"
                    )
                }

                GridRow {

                    Text("Bank")
                        .foregroundStyle(.secondary)

                    Text(transaction.bank)
                }

                GridRow {

                    Text("Date")
                        .foregroundStyle(.secondary)

                    Text(
                        transaction.date.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                    )
                }
            }
            .font(.subheadline)

            HStack(spacing: 12) {

                Button(
                    "Discard",
                    action: onDiscard
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .foregroundStyle(.primary)
                .clipShape(
                    RoundedRectangle(cornerRadius: 10)
                )

                Button(
                    "Save",
                    action: onSave
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green)
                .foregroundStyle(.white)
                .clipShape(
                    RoundedRectangle(cornerRadius: 10)
                )
            }
            .fontWeight(.medium)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
    }
}

#Preview {

    ParsedPreviewCard(
        transaction: Transaction.preview,

        onSave: {},

        onDiscard: {}
    )
    .padding()
}
