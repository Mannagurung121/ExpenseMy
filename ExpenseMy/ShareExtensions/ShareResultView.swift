//
//  ShareResultView.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 07/05/26.
//
import SwiftUI

struct ShareResultView: View {

    let success: Bool
    let message: String
    let onDone: () -> Void

    @State private var appeared = false

    var body: some View {

        VStack(spacing: 24) {

            Spacer()

            // MARK: Icon

            ZStack {

                Circle()
                    .fill(
                        success
                        ? Color.green.opacity(0.12)
                        : Color.red.opacity(0.12)
                    )
                    .frame(
                        width: 90,
                        height: 90
                    )

                Image(
                    systemName:
                        success
                        ? "checkmark.circle.fill"
                        : "xmark.circle.fill"
                )
                .font(.system(size: 48))
                .foregroundStyle(
                    success
                    ? .green
                    : .red
                )
            }
            .scaleEffect(
                appeared ? 1 : 0.5
            )
            .opacity(
                appeared ? 1 : 0
            )

            // MARK: Message

            VStack(spacing: 8) {

                Text(
                    success
                    ? "Transaction saved!"
                    : "Couldn't parse SMS"
                )
                .font(.title3)
                .fontWeight(.semibold)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(
                appeared ? 1 : 0
            )

            Spacer()

            // MARK: Done Button

            Button(action: onDone) {

                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        success
                        ? Color.green
                        : Color(.systemGray4)
                    )
                    .foregroundStyle(
                        success
                        ? .white
                        : .primary
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 14)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(
                appeared ? 1 : 0
            )
        }
        .onAppear {

            withAnimation(
                .spring(duration: 0.5)
            ) {

                appeared = true
            }
        }
    }
}

// MARK: - Preview

//#Preview("Success") {
//
//    ShareResultView(
//        success: true,
//
//        message:
//            "₹450 spent at Swiggy was added to your expenses.",
//
//        onDone: {
//
//        }
//    )
//}
//
//#Preview("Failed") {
//
//    ShareResultView(
//        success: false,
//
//        message:
//            "We couldn't detect a valid bank transaction SMS.",
//
//        onDone: {
//
//        }
//    )
//}
