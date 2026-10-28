

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var allTransactions: [Transaction]
    @Environment(\.modelContext) private var context

    @State private var userName: String = UserManager.shared.userName
    @State private var userEmail: String = UserManager.shared.userEmail
    @State private var userDOB: Date = UserManager.shared.userDOB
    @State private var isEditing: Bool = false
    @State private var isSaved: Bool = false

    private var totalSpent: Double {
        allTransactions.filter { $0.type == .debit }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalTransactions: Int {
        allTransactions.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                // Doodle blob top
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 280)
                    .offset(x: 140, y: -180)
                    .blur(radius: 50)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // MARK: — Avatar + Info
                        VStack(spacing: 16) {
                            ZStack {
                                // Outer ring
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.purple, .indigo, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                                    .frame(width: 96, height: 96)

                                // Avatar
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.8), .indigo],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 86, height: 86)

                                Text(
                                    UserManager.shared.initials.isEmpty
                                    ? "👤"
                                    : UserManager.shared.initials
                                )
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            }

                            VStack(spacing: 4) {
                                Text(userName.isEmpty ? "Add your name" : userName)
                                    .font(.title3)
                                    .fontWeight(.bold)

                                HStack(spacing: 6) {
                                    Text("🇮🇳 +91")
                                    Text(UserManager.shared.phoneNumber)
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 20)

                        // MARK: — Stats row
                        HStack(spacing: 12) {
                            ProfileStatCard(
                                emoji: "💸",
                                value: "₹\(Int(totalSpent))",
                                label: "Total spent",
                                accent: .red
                            )
                            ProfileStatCard(
                                emoji: "📋",
                                value: "\(totalTransactions)",
                                label: "Transactions",
                                accent: .purple
                            )
                            ProfileStatCard(
                                emoji: "🏦",
                                value: uniqueBanks,
                                label: "Banks",
                                accent: .blue
                            )
                        }
                        .padding(.horizontal, 20)

                        // MARK: — Edit Form
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Personal details")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Spacer()
                                Button {
                                    withAnimation { isEditing.toggle() }
                                    if !isEditing { saveProfile() }
                                } label: {
                                    Text(isEditing ? "Save" : "Edit")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(isEditing ? .white : .purple)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 7)
                                        .background(
                                            isEditing
                                            ? LinearGradient(colors: [.purple, .indigo],
                                                             startPoint: .leading, endPoint: .trailing)
                                            : LinearGradient(colors: [Color.purple.opacity(0.12),
                                                                       Color.purple.opacity(0.12)],
                                                             startPoint: .leading, endPoint: .trailing)
                                        )
                                        .clipShape(Capsule())
                                }
                            }

                            // Name field
                            ProfileField(
                                icon: "person.fill",
                                label: "Full name",
                                placeholder: "Manan Singh Gurung",
                                text: $userName,
                                isEditing: isEditing,
                                keyboard: .default
                            )

                            // Email field
                            ProfileField(
                                icon: "envelope.fill",
                                label: "Email",
                                placeholder: "manan@example.com",
                                text: $userEmail,
                                isEditing: isEditing,
                                keyboard: .emailAddress
                            )

                            // DOB
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundStyle(.purple)
                                        .frame(width: 16)
                                    Text("Date of birth")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                }

                                if isEditing {
                                    DatePicker(
                                        "",
                                        selection: $userDOB,
                                        in: ...Date(),
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(.purple)
                                    .padding(.leading, 24)
                                } else {
                                    Text(userDOB.formatted(date: .long, time: .omitted))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.leading, 24)
                                        .foregroundStyle(
                                            UserDefaults.standard.double(forKey: "userDOB") == 0
                                            ? .secondary : .primary
                                        )
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 20)

                        // Save success banner
                        if isSaved {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Profile saved!")
                                    .fontWeight(.medium)
                            }
                            .font(.subheadline)
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        Text("SpendSense v1.0 • Made in India")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
}
        
    }

    private var uniqueBanks: String {
        let banks = Set(allTransactions.map { $0.bank })
        return "\(banks.count)"
    }

    private func saveProfile() {
        UserManager.shared.userName = userName
        UserManager.shared.userEmail = userEmail
        UserManager.shared.userDOB = userDOB

        withAnimation {
            isSaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { isSaved = false }
        }
    }
}

// MARK: — Profile Stat Card
struct ProfileStatCard: View {
    let emoji: String
    let value: String
    let label: String
    let accent: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.title2)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: — Profile Field
struct ProfileField: View {
    let icon: String
    let label: String
    let placeholder: String
    @Binding var text: String
    let isEditing: Bool
    let keyboard: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.purple)
                    .frame(width: 16)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            if isEditing {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.purple.opacity(0.4), lineWidth: 1.5)
                    )
            } else {
                Text(text.isEmpty ? placeholder : text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(text.isEmpty ? .secondary : .primary)
                    .padding(.leading, 24)
            }
        }
    }
}
//#Preview{
//    ProfileView()
//}
//
