//
//  Transactions.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 06/05/26.
//

import SwiftData
import Foundation

enum TransactionType: String, Codable {
    case debit = "debit"
    case credit = "credit"
}

enum Category: String, CaseIterable, Codable {
    case food          = "Food & Dining"
    case transport     = "Transport"
    case recharge      = "Recharge & Bills"
    case shopping      = "Shopping"
    case entertainment = "Entertainment"
    case healthcare    = "Healthcare"
    case rent          = "Rent & Housing"
    case uncategorized = "Others"

    var emoji: String {
        switch self {
        case .food:          return "🍔"
        case .transport:     return "🚗"
        case .recharge:      return "📱"
        case .shopping:      return "🛍️"
        case .entertainment: return "🎬"
        case .healthcare:    return "💊"
        case .rent:          return "🏠"
        case .uncategorized: return "📦"
        }
    }

    var color: String {
        switch self {
        case .food:          return "orange"
        case .transport:     return "blue"
        case .recharge:      return "purple"
        case .shopping:      return "pink"
        case .entertainment: return "red"
        case .healthcare:    return "green"
        case .rent:          return "brown"
        case .uncategorized: return "gray"
        }
    }
}

@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var transactionType: String      
    var merchant: String
    var categoryRaw: String
    var bank: String
    var date: Date
    var rawSMS: String

    var type: TransactionType {
        TransactionType(rawValue: transactionType) ?? .debit
    }

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .uncategorized }
        set { categoryRaw = newValue.rawValue }
    }

    init(amount: Double,
         type: TransactionType,
         merchant: String,
         category: Category,
         bank: String,
         date: Date,
         rawSMS: String) {
        self.id = UUID()
        self.amount = amount
        self.transactionType = type.rawValue
        self.merchant = merchant
        self.categoryRaw = category.rawValue
        self.bank = bank
        self.date = date
        self.rawSMS = rawSMS
    }
}
import Foundation

extension Transaction {

    static let preview = Transaction(
        amount: 450,
        type: .debit,
        merchant: "Swiggy",
        category: .food,
        bank: "SBI",
        date: .now,
        rawSMS: "Done"
    )
}
