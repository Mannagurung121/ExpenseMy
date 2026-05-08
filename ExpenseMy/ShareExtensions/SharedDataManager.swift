//
//  SharedDataManager.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 07/05/26.
//

import Foundation
import WidgetKit

struct SharedDataManager {

    static let groupID = "group.learns.ExpenseMy"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: groupID)
    }

    // MARK: - Pending transactions (Share Extension → Main App)

    static func savePendingTransaction(_ dto: TransactionDTO) {
        var existing = getPendingDTOs()
        existing.append(dto)
        if let data = try? JSONEncoder().encode(existing) {
            defaults?.set(data, forKey: "pendingTransactions")
        }
    }

    static func getPendingDTOs() -> [TransactionDTO] {
        guard let data = defaults?.data(forKey: "pendingTransactions"),
              let dtos = try? JSONDecoder().decode([TransactionDTO].self, from: data) else {
            return []
        }
        return dtos
    }

    static func clearPendingTransactions() {
        defaults?.removeObject(forKey: "pendingTransactions")
    }

    // MARK: - Widget data (Main App → Widget)

    static func saveWidgetData(totalSpent: Double,
                               topCategory: String,
                               topEmoji: String,
                               count: Int) {
        defaults?.set(totalSpent,    forKey: "w_totalSpent")
        defaults?.set(topCategory,   forKey: "w_topCategory")
        defaults?.set(topEmoji,      forKey: "w_topEmoji")
        defaults?.set(count,         forKey: "w_count")
        defaults?.set(Date(),        forKey: "w_lastUpdated")
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func getWidgetData() -> WidgetData {
        WidgetData(
            totalSpent:   defaults?.double(forKey: "w_totalSpent")  ?? 0,
            topCategory:  defaults?.string(forKey: "w_topCategory") ?? "None",
            topEmoji:     defaults?.string(forKey: "w_topEmoji")    ?? "📦",
            count:        defaults?.integer(forKey: "w_count")      ?? 0,
            lastUpdated:  defaults?.object(forKey: "w_lastUpdated") as? Date ?? Date()
        )
    }
}

// Widget data model
struct WidgetData {
    let totalSpent:  Double
    let topCategory: String
    let topEmoji:    String
    let count:       Int
    let lastUpdated: Date
}
