import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var context
    @Query private var allTransactions: [Transaction]

    @State private var smsText: String = ""
    @State private var parsedTransaction: Transaction? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showPreview = false
    @State private var showSuccess = false
    @State private var isParsing = false

    @FocusState private var isEditorFocused: Bool

    let samples: [SampleSMS] = sampleSMSList

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Hero header
                    VStack(spacing: 6) {
                        Text("💸")
                            .font(.system(size: 48))

                        Text("Add Transaction")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Paste your bank SMS and let AI do the rest")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // SMS Input card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Paste SMS", systemImage: "message.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.purple)
                            Spacer()
                            if !smsText.isEmpty {
                                Button {
                                    withAnimation {
                                        smsText = ""
                                        showPreview = false
                                        parsedTransaction = nil
                                        isEditorFocused = false
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .font(.title3)
                                }
                            }
                        }

                        ZStack(alignment: .topLeading) {
                            if smsText.isEmpty {
                                Text("Your A/c XX1234 is debited by Rs.450...")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $smsText)
                                .font(.subheadline)
                                .frame(minHeight: 100)
                                .focused($isEditorFocused)
                                .scrollContentBackground(.hidden)
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done") {
                                            isEditorFocused = false
                                        }
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.purple)
                                    }
                                }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isEditorFocused
                                ? Color.purple.opacity(0.5)
                                : Color.clear,
                                lineWidth: 1.5
                            )
                    )

                    // Sample bank pills
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick test")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(samples, id: \.bankName) { sample in
                                    Button {
                                        withAnimation {
                                            smsText = sample.sms
                                            isEditorFocused = false
                                            showPreview = false
                                            parsedTransaction = nil
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(bankEmoji(sample.bankName))
                                            Text(sample.bankName)
                                                .fontWeight(.medium)
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            smsText == sample.sms
                                            ? Color.purple
                                            : Color(.systemGray5)
                                        )
                                        .foregroundStyle(
                                            smsText == sample.sms
                                            ? Color.white
                                            : Color.primary
                                        )
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    // Parse button
                    Button(action: parseSMS) {
                        HStack(spacing: 10) {
                            if isParsing {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "wand.and.stars")
                                    .font(.subheadline)
                            }
                            Text(isParsing ? "Parsing..." : "Parse SMS")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            smsText.isEmpty
                            ? Color(.systemGray4)
                            : Color.purple
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .scaleEffect(smsText.isEmpty ? 1 : 1.0)
                    }
                    .disabled(smsText.isEmpty || isParsing)

                    // Success banner
                    if showSuccess {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Transaction saved!")
                                    .fontWeight(.semibold)
                                Text("Check dashboard to see your spending")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Parsed result card
                    if showPreview, let txn = parsedTransaction {
                        CoolParsedCard(
                            transaction: txn,
                            onSave: { saveTransaction(txn) },
                            onDiscard: {
                                withAnimation {
                                    showPreview = false
                                    parsedTransaction = nil
                                }
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // How to use — collapsed at bottom
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Open Messages app on your iPhone", systemImage: "1.circle")
                            Label("Copy any bank debit/credit SMS", systemImage: "2.circle")
                            Label("Paste above and tap Parse", systemImage: "3.circle")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    } label: {
                        Label("How to use", systemImage: "info.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .onTapGesture { isEditorFocused = false }
            .navigationBarHidden(true)
            .alert("Couldn't Parse", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func bankEmoji(_ name: String) -> String {
        switch name.lowercased() {
        case "sbi":    return "🏦"
        case "hdfc":   return "💙"
        case "icici":  return "🧡"
        case "kotak":  return "❤️"
        case "credit": return "💚"
        default:       return "🏧"
        }
    }

    private func parseSMS() {
        isEditorFocused = false
        let trimmed = smsText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation { isParsing = true; showSuccess = false }

        // Slight delay for UX feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation { isParsing = false }

            if let transaction = SMSParser.parse(trimmed) {
                withAnimation(.spring(duration: 0.5)) {
                    parsedTransaction = transaction
                    showPreview = true
                }
            } else {
                alertMessage = "Could not parse this SMS.\nMake sure it's a bank transaction SMS and not an OTP."
                showAlert = true
            }
        }
    }

    private func saveTransaction(_ txn: Transaction) {
        context.insert(txn)
        try? context.save()
        updateWidget()

        withAnimation(.spring(duration: 0.4)) {
            smsText = ""
            showPreview = false
            parsedTransaction = nil
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { showSuccess = false }
        }
    }

    private func updateWidget() {
        let startOfMonth = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        )!
        let debits = allTransactions.filter {
            $0.type == .debit && $0.date >= startOfMonth
        }
        let total = debits.reduce(0) { $0 + $1.amount }
        let grouped = Dictionary(grouping: debits) { $0.category }
        let top = grouped.max { a, b in
            let aTotal = a.value.reduce(0) { $0 + $1.amount }
            let bTotal = b.value.reduce(0) { $0 + $1.amount }
            return aTotal < bTotal
        }?.key

        SharedDataManager.saveWidgetData(
            totalSpent: total,
            topCategory: top?.rawValue ?? "None",
            topEmoji: top?.emoji ?? "📦",
            count: debits.count
        )
    }
}

// MARK: - Cool Parsed Result Card
struct CoolParsedCard: View {
    let transaction: Transaction
    let onSave: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // Top colored strip
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Parsed successfully!")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(transaction.merchant)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                Spacer()
                Text(transaction.category.emoji)
                    .font(.system(size: 40))
            }
            .padding(16)
            .background(
                transaction.type == .debit
                ? Color.red.opacity(0.8)
                : Color.green.opacity(0.8)
            )

            // Details grid
            VStack(spacing: 0) {
                HStack {
                    DetailCell(label: "Amount",
                               value: "₹\(transaction.amount, default: "%.2f")",
                               color: transaction.type == .debit ? .red : .green)
                    Divider()
                    DetailCell(label: "Type",
                               value: transaction.type == .debit ? "Debit" : "Credit",
                               color: .primary)
                }
                .frame(height: 60)

                Divider()

                HStack {
                    DetailCell(label: "Category",
                               value: transaction.category.rawValue,
                               color: .primary)
                    Divider()
                    DetailCell(label: "Bank",
                               value: transaction.bank,
                               color: .primary)
                }
                .frame(height: 60)

                Divider()

                HStack {
                    DetailCell(label: "Date",
                               value: transaction.date.formatted(date: .abbreviated, time: .omitted),
                               color: .primary)
                    Divider()
                    DetailCell(label: "Status",
                               value: "✓ Ready",
                               color: .green)
                }
                .frame(height: 60)
            }
            .background(Color(.systemGray6))

            // Action buttons
            HStack(spacing: 0) {
                Button(action: onDiscard) {
                    Text("Discard")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Button(action: onSave) {
                    Text("Save →")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.purple)
                }
            }
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

struct DetailCell: View {
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: Transaction.self)
}

