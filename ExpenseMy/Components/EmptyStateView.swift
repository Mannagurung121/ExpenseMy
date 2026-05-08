//
//  EmptyStateView.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 06/05/26.
//

import SwiftUI

struct EmptyStateView: View {

    var body: some View {

        VStack(spacing: 16) {

            Image(systemName: "tray")
                .font(.system(size: 52))
                .foregroundColor(.secondary)

            Text("No transactions yet")
                .font(.title3)
                .fontWeight(.medium)

            Text("""
Go to Add SMS tab and paste
a bank transaction SMS to start
""")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
    }
}

#Preview {

    EmptyStateView()
}
