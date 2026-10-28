

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
        ZStack {
            darkBackground
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    heroCard
                    detailsCard
                    categoryEditor
                    rawSMSCard
                    saveButton
                    deleteButton
                }
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Details")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(Color(hex: "#0D0B1E"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .confirmationDialog(
            "Delete this transaction?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                context.delete(transaction)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: — Background
    private var darkBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0D0B1E"), Color(hex: "#130D2E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Canvas { ctx, size in
                let spacing: CGFloat = 28
                var x: CGFloat = 0
                while x < size.width {
                    var y: CGFloat = 0
                    while y < size.height {
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x, y: y,
                                                   width: 1.5, height: 1.5)),
                            with: .color(.white.opacity(0.06))
                        )
                        y += spacing
                    }
                    x += spacing
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: — Hero Card
    private var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#7B2FBE"), Color(hex: "#4A1A8C")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

            heroDecorations

            heroContent
        }
        .padding(.horizontal, 20)
        .shadow(color: .purple.opacity(0.3), radius: 20, y: 8)
    }

    private var heroDecorations: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
                .frame(width: 180)
                .offset(x: 100, y: -20)
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 90)
                .offset(x: -100, y: 30)
        }
    }

    private var heroContent: some View {
        VStack(spacing: 10) {
            Text(transaction.category.emoji)
                .font(.system(size: 52))

            Text(amountText)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)

            Text(transaction.merchant)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.9))

            Text(transaction.date.formatted(date: .long, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))

            typeBadge
        }
        .padding(24)
    }

    private var amountText: String {
        let sign = transaction.type == .debit ? "-" : "+"
        return "\(sign)₹\(String(format: "%.2f", transaction.amount))"
    }

    private var typeBadge: some View {
        let isDebit = transaction.type == .debit
        return Text(isDebit ? "⬆ Debit" : "⬇ Credit")
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(isDebit ? Color.red.opacity(0.25) : Color.green.opacity(0.25))
            .foregroundStyle(isDebit ? Color(hex: "#FF6B6B") : Color(hex: "#55EFC4"))
            .clipShape(Capsule())
    }

    // MARK: — Details Card
    private var detailsCard: some View {
        VStack(spacing: 0) {
            DarkDetailRow(label: "🏦 Bank", value: transaction.bank)
            Divider().background(Color.white.opacity(0.08))
            DarkDetailRow(
                label: "💳 Type",
                value: transaction.type == .debit ? "Debit" : "Credit",
                valueColor: transaction.type == .debit
                    ? Color(hex: "#FF6B6B")
                    : Color(hex: "#55EFC4")
            )
            Divider().background(Color.white.opacity(0.08))
            DarkDetailRow(
                label: "📅 Date",
                value: transaction.date.formatted(date: .complete, time: .omitted)
            )
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: — Category Editor
    private var categoryEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Category")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Spacer()
                Text("Tap to change")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(Category.allCases, id: \.self) { cat in
                    categoryButton(for: cat)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private func categoryButton(for cat: Category) -> some View {
        let isSelected = selectedCategory == cat
        return Button {
            withAnimation(.spring(duration: 0.2)) {
                selectedCategory = cat
            }
        } label: {
            HStack(spacing: 8) {
                Text(cat.emoji)
                Text(cat.rawValue.components(separatedBy: " ").first ?? "")
                    .font(.subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.purple)
                        .font(.caption)
                }
            }
            .padding(12)
            .background(isSelected ? Color.purple.opacity(0.25) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.purple.opacity(0.6) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: — Raw SMS Card
    private var rawSMSCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Original SMS", systemImage: "message.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text(transaction.rawSMS)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: — Save Button
    private var saveButton: some View {
        let isDisabled = selectedCategory == transaction.category
        return Button {
            transaction.category = selectedCategory
            try? context.save()
            dismiss()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save changes")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isDisabled
                ? AnyShapeStyle(Color.white.opacity(0.08))
                : AnyShapeStyle(LinearGradient(
                    colors: [.purple, .indigo],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isDisabled)
        .padding(.horizontal, 20)
    }

    // MARK: — Delete Button
    private var deleteButton: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete transaction")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.12))
            .foregroundStyle(Color(hex: "#FF6B6B"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }
}


#Preview {
    NavigationStack {
        TransactionDetailView(
            transaction: Transaction(
                amount: 450,
                type: .debit,
                merchant: "Swiggy",
                category: .food,
                bank: "Kotak",
                date: Date(),
                rawSMS: "Your A/c XX1234 is debited by Rs.450 on 08-05-26. UPI-SWIGGY"
            )
        )
        .modelContainer(for: Transaction.self, inMemory: true)
    }
}


#Preview {
    NavigationStack {
        TransactionDetailView(
            transaction: Transaction(
                amount: 450,
                type: .debit,
                merchant: "Swiggy",
                category: .food,
                bank: "Kotak",
                date: Date(),
                rawSMS: "Your A/c XX1234 is debited by Rs.450.00 on 08-05-26. Info: UPI-SWIGGY"
            )
        )
        .modelContainer(for: Transaction.self, inMemory: true)
    }
}
