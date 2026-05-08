//
//  TransactionDTO.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 07/05/26.
//

//
//  TransactionDTO.swift
//  ExpenseMy
//

import Foundation

// Codable version of Transaction — SwiftData @Model is not Codable
struct TransactionDTO: Codable, Identifiable {
    let id:              UUID
    let amount:          Double
    let transactionType: String
    let merchant:        String
    let categoryRaw:     String
    let bank:            String
    let date:            Date
    let rawSMS:          String

    init(from transaction: Transaction) {
        self.id              = transaction.id
        self.amount          = transaction.amount
        self.transactionType = transaction.transactionType
        self.merchant        = transaction.merchant
        self.categoryRaw     = transaction.categoryRaw
        self.bank            = transaction.bank
        self.date            = transaction.date
        self.rawSMS          = transaction.rawSMS
    }

    // Convert back to Transaction for saving in main app
    func toTransaction() -> Transaction {
        Transaction(
            amount:   amount,
            type:     TransactionType(rawValue: transactionType) ?? .debit,
            merchant: merchant,
            category: Category(rawValue: categoryRaw) ?? .uncategorized,
            bank:     bank,
            date:     date,
            rawSMS:   rawSMS
        )
    }
}
