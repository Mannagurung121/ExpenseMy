//
//  TransactionModelTests.swift
//  ExpenseMyTests
//

import XCTest
import SwiftData
@testable import ExpenseMy

final class TransactionModelTests: XCTestCase {

    var container: ModelContainer!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Transaction.self, configurations: config)
    }

    override func tearDown() {
        container = nil
    }

    // MARK: - Helpers

    private func makeTransaction(
        amount: Double = 100.0,
        type: TransactionType = .debit,
        merchant: String = "Test Merchant",
        category: Category = .uncategorized,
        bank: String = "SBI",
        rawSMS: String = "test sms"
    ) -> Transaction {
        let tx = Transaction(
            amount: amount,
            type: type,
            merchant: merchant,
            category: category,
            bank: bank,
            date: Date(),
            rawSMS: rawSMS
        )
        container.mainContext.insert(tx)
        return tx
    }

    // MARK: - Tests

    func testTransactionInitialization() {
        // Arrange
        let date = Date()

        // Act
        let tx = Transaction(
            amount: 499.99,
            type: .debit,
            merchant: "Swiggy",
            category: .food,
            bank: "HDFC",
            date: date,
            rawSMS: "Rs.499.99 debited. -HDFC"
        )
        container.mainContext.insert(tx)

        // Assert
        XCTAssertEqual(tx.amount, 499.99)
        XCTAssertEqual(tx.merchant, "Swiggy")
        XCTAssertEqual(tx.bank, "HDFC")
        XCTAssertEqual(tx.rawSMS, "Rs.499.99 debited. -HDFC")
        XCTAssertEqual(tx.transactionType, TransactionType.debit.rawValue)
        XCTAssertEqual(tx.categoryRaw, Category.food.rawValue)
        XCTAssertEqual(tx.date, date)
    }

    func testTransactionTypeComputedProperty() {
        // Arrange
        let debitTx = makeTransaction(type: .debit)
        let creditTx = makeTransaction(type: .credit)

        // Act & Assert
        XCTAssertEqual(debitTx.type, .debit)
        XCTAssertEqual(creditTx.type, .credit)
    }

    func testCategoryComputedPropertyGet() {
        // Arrange
        let tx = makeTransaction(category: .food)

        // Act
        let category = tx.category

        // Assert
        XCTAssertEqual(category, .food)
        XCTAssertEqual(tx.categoryRaw, Category.food.rawValue)
    }

    func testCategoryComputedPropertySet() {
        // Arrange
        let tx = makeTransaction(category: .uncategorized)

        // Act
        tx.category = .shopping

        // Assert
        XCTAssertEqual(tx.categoryRaw, Category.shopping.rawValue)
        XCTAssertEqual(tx.category, .shopping)
    }

    func testInvalidTransactionTypeDefaultsToDebit() {
        // Arrange
        let tx = makeTransaction(type: .debit)

        // Act
        tx.transactionType = "invalid_type"

        // Assert
        XCTAssertEqual(tx.type, .debit, "Unknown transactionType raw value must fall back to .debit")
    }

    func testInvalidCategoryDefaultsToUncategorized() {
        // Arrange
        let tx = makeTransaction(category: .food)

        // Act
        tx.categoryRaw = "NonExistentCategory"

        // Assert
        XCTAssertEqual(tx.category, .uncategorized, "Unknown categoryRaw value must fall back to .uncategorized")
    }

    func testUUIDIsUnique() {
        // Arrange
        let tx1 = makeTransaction()
        let tx2 = makeTransaction()

        // Act — UUIDs are assigned in init via UUID()

        // Assert
        XCTAssertNotEqual(tx1.id, tx2.id)
    }
}
