//
//  DarkDetailRow.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 13/05/26.
//

import SwiftUI

struct DarkDetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .white

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

#Preview {
    DarkDetailRow(label: "Helllo", value: "Hello" )
}
