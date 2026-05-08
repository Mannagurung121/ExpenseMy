//
//  TransactionDetailView.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 07/05/26.
//

import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let transaction: Transaction

    @State private var selectedCategory: Category
    @State private var showDeleteConfirm = false

    init(transaction: Transaction) {
        self.transaction = transaction
        _selectedCategory = State(initialValue: transaction.category)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Amount hero
                    VStack(spacing: 6) {
                        Text(transaction.category.emoji)
                            .font(.system(size: 48))

                        Text("\(transaction.type == .debit ? "-" : "+")₹\(transaction.amount, specifier: "%.2f")")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(transaction.type == .debit ? .red : .green)

                        Text(transaction.merchant)
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Text(transaction.date.formatted(date: .long, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Details card
                    VStack(spacing: 0) {
                        DetailRow(label: "Bank", value: transaction.bank)
                        Divider().padding(.leading, 16)
                        DetailRow(label: "Type",
                                  value: transaction.type == .debit ? "Debit" : "Credit",
                                  valueColor: transaction.type == .debit ? .red : .green)
                        Divider().padding(.leading, 16)
                        DetailRow(label: "Date",
                                  value: transaction.date.formatted(date: .complete, time: .omitted))
                    }
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Category editor
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.headline)
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(Category.allCases, id: \.self) { cat in
                                Button {
                                    selectedCategory = cat
                                } label: {
                                    HStack {
                                        Text(cat.emoji)
                                        Text(cat.rawValue)
                                            .font(.subheadline)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                        Spacer()
                                        if selectedCategory == cat {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.purple)
                                                .font(.caption)
                                        }
                                    }
                                    .padding(10)
                                    .background(
                                        selectedCategory == cat
                                        ? Color.purple.opacity(0.1)
                                        : Color(.systemGray6)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedCategory == cat
                                                    ? Color.purple.opacity(0.4)
                                                    : Color.clear, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Raw SMS
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Original SMS")
                            .font(.headline)

                        Text(transaction.rawSMS)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Delete button
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete transaction", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Transaction details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        transaction.category = selectedCategory
                        try? context.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedCategory == transaction.category)
                }
            }
            .confirmationDialog("Delete this transaction?",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    context.delete(transaction)
                    try? context.save()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
#Preview {

    TransactionDetailView(
        transaction: Transaction.preview
    )
    .modelContainer(
        for: Transaction.self,
        inMemory: true
    )
}
