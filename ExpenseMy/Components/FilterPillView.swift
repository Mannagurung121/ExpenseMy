//
//  FilterPillView.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 06/05/26.
//

import SwiftUI
import UIKit
struct FilterPillView: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected
                    ? Color.purple
                    : Color(.systemGray5)
                )
                .foregroundColor(
                    isSelected
                    ? .white
                    : .primary
                )
                .clipShape(Capsule())
        }
    }
}

#Preview {

    VStack(spacing: 16) {

        FilterPillView(
            title: "Food",
            isSelected: true
        ) {

        }

        FilterPillView(
            title: "Shopping",
            isSelected: false
        ) {

        }
    }
    .padding()
}
