//
//  ExpenseMyTests.swift
//  ExpenseMyTests
//

import XCTest
@testable import ExpenseMy

final class ExpenseMyTests: XCTestCase {

    // MARK: - Amount Extraction

    func testAmountExtractionWithRsFormat() {
        // Arrange
        let sms = "Your a/c is debited for Rs.450.00 on 14-06-26. -SBI"

        // Act
        let amount = SMSParser.extractAmount(from: sms)

        // Assert
        XCTAssertEqual(amount, 450.00)
    }

    func testAmountExtractionWithINRFormat() {
        // Arrange
        let sms = "INR 1,234.50 debited from your HDFC a/c. Ref 123456."

        // Act
        let amount = SMSParser.extractAmount(from: sms)

        // Assert
        XCTAssertEqual(amount, 1234.50)
    }

    func testAmountExtractionWithCommas() {
        // Arrange
        let sms = "Rs.12,500 debited from your a/c XX9876. -ICICI"

        // Act
        let amount = SMSParser.extractAmount(from: sms)

        // Assert
        XCTAssertEqual(amount, 12500.0)
    }

    func testAmountExtractionReturnsNilForNoAmount() {
        // Arrange
        let sms = "Your account details have been updated successfully."

        // Act
        let amount = SMSParser.extractAmount(from: sms)

        // Assert
        XCTAssertNil(amount)
    }

    // MARK: - Transaction Filter

    func testOTPMessageReturnsNil() {
        // Arrange
        let sms = "Your OTP for Rs.500 transaction is 123456. Do not share this OTP with anyone. -HDFC"

        // Act
        let result = SMSParser.parse(sms)

        // Assert
        XCTAssertNil(result, "OTP SMS with amount must not be parsed as a transaction")
    }

    func testPromotionalMessageReturnsNil() {
        // Arrange — no transaction verb (debited/credited/sent/etc.), so isTransactionSMS returns false
        let sms = "Great news! Rs.100 off on your next order at SWIGGY. Use code SAVE100. Offer valid today only."

        // Act
        let result = SMSParser.parse(sms)

        // Assert
        XCTAssertNil(result, "Promotional SMS without a transaction keyword must return nil")
    }

    // MARK: - Type Detection

    func testDebitTypeDetection() {
        // Arrange
        let sms = "Your a/c XX1234 is debited for Rs.300 on 14-06-26. -SBI"

        // Act
        let type_ = SMSParser.extractType(from: sms)

        // Assert
        XCTAssertEqual(type_, .debit)
    }

    func testCreditTypeDetection() {
        // Arrange
        let sms = "Rs.5,000.00 credited to your HDFC Bank a/c XX5678 on 14-06-26."

        // Act
        let type_ = SMSParser.extractType(from: sms)

        // Assert
        XCTAssertEqual(type_, .credit)
    }

    func testSentTypeDetection() {
        // Arrange — Kotak "sent" format; money going out so type must be debit
        let sms = "Rs.200.00 sent to VPA rapido@kotak on 14-06-26. Kotak Bank."

        // Act
        let type_ = SMSParser.extractType(from: sms)

        // Assert
        XCTAssertEqual(type_, .debit)
    }

    // MARK: - Merchant Extraction

    func testMerchantExtraction() {
        // Arrange — "to VPA merchant@upi" UPI pattern
        let sms = "Rs.250.00 debited from your SBI a/c. Txn to VPA swiggy@upi on 14-06-26. -SBI"

        // Act
        let merchant = SMSParser.extractMerchant(from: sms)

        // Assert
        XCTAssertEqual(merchant, "Swiggy")
    }

    // MARK: - Bank Extraction

    func testBankExtraction() {
        // Arrange
        let sms = "Your ICICI Bank a/c XX1234 is debited for Rs.100. -ICICI"

        // Act
        let bank = SMSParser.extractBank(from: sms)

        // Assert
        XCTAssertEqual(bank, "ICICI")
    }

    // MARK: - Date Extraction

    func testDateExtraction() {
        // Arrange — dd-MM-yy format used by SBI
        let sms = "Your a/c debited Rs.500 on 15-05-26 by UPI. -SBI"

        // Act
        let date = SMSParser.extractDate(from: sms)

        // Assert
        XCTAssertNotNil(date)
        let cal = Calendar.current
        XCTAssertEqual(cal.component(.day, from: date!), 15)
        XCTAssertEqual(cal.component(.month, from: date!), 5)
    }

    // MARK: - Full SMS Integration

    func testFullSBIDebitSMS() {
        // Arrange
        let sms = "Your a/c XX1234 is debited for Rs.450.00 on 15-05-26 by UPI. Merchant: SWIGGY. Ref No 412345678901. -SBI"

        // Act
        let transaction = SMSParser.parse(sms)

        // Assert
        XCTAssertNotNil(transaction)
        XCTAssertEqual(transaction?.amount, 450.00)
        XCTAssertEqual(transaction?.type, .debit)
        XCTAssertEqual(transaction?.bank, "SBI")
        // "swiggy" appears in rawText so CategoryClassifier resolves .food even when merchant is Unknown
        XCTAssertEqual(transaction?.category, .food)
    }

    func testFullHDFCCreditSMS() {
        // Arrange
        let sms = "Rs.5,000.00 credited to your HDFC Bank a/c XX5678 on 14/06/2026. Avl Bal: Rs.50,000.00. -HDFC"

        // Act
        let transaction = SMSParser.parse(sms)

        // Assert
        XCTAssertNotNil(transaction)
        XCTAssertEqual(transaction?.amount, 5000.00)
        XCTAssertEqual(transaction?.type, .credit)
        XCTAssertEqual(transaction?.bank, "HDFC")
    }

    func testFullKotakSentSMS() {
        // Arrange
        let sms = "Rs.2,000.00 sent to VPA rapido@kotak on 14-06-26. Ref 987654321. Kotak Bank"

        // Act
        let transaction = SMSParser.parse(sms)

        // Assert
        XCTAssertNotNil(transaction)
        XCTAssertEqual(transaction?.amount, 2000.00)
        XCTAssertEqual(transaction?.type, .debit)
        XCTAssertEqual(transaction?.merchant, "Rapido")
        XCTAssertEqual(transaction?.bank, "Kotak")
    }

    func testFullICICIDebitSMS() {
        // Arrange
        let sms = "Your ICICI Bank a/c XX9876 has been debited for Rs.1,234.50 on 14-06-26. UPI-AMAZON. Avl Bal Rs.45,678.90. -ICICI"

        // Act
        let transaction = SMSParser.parse(sms)

        // Assert
        XCTAssertNotNil(transaction)
        XCTAssertEqual(transaction?.amount, 1234.50)
        XCTAssertEqual(transaction?.type, .debit)
        XCTAssertEqual(transaction?.merchant, "Amazon")
        XCTAssertEqual(transaction?.bank, "ICICI")
        XCTAssertEqual(transaction?.category, .shopping)
    }

    // MARK: - Security

    func testReDoSResistance() {
        // Arrange — 10 000+ character string with repeated amount-like patterns
        let malformed = String(repeating: "Rs.1,2,3,4,5,6,7,8,9 debited from ", count: 500)

        // Act
        let start = Date()
        _ = SMSParser.parse(malformed)
        let elapsed = Date().timeIntervalSince(start)

        // Assert
        XCTAssertLessThan(elapsed, 2.0, "Parser took too long — potential ReDoS vulnerability")

        measure {
            _ = SMSParser.parse(malformed)
        }
    }

    func testSMSWithSpecialCharactersDoesNotCrash() {
        // Arrange
        let sms = "💸 Rs.500 debited!! <script>alert('xss')</script> from a/c XX1234 on 14-06-26. 你好 ₹ -SBI"

        // Act — test passes if no crash occurs; nil or Transaction are both acceptable
        _ = SMSParser.parse(sms)

        // Assert
        XCTAssert(true, "Parser must not crash on unicode, emoji, or HTML input")
    }

    func testSMSInjectionAttempt() {
        // Arrange
        let sms = "Rs.100 debited from a/c XX1234 on 14-06-26. Info: UPI-'; DROP TABLE--. -SBI"

        // Act
        let result = SMSParser.parse(sms)

        // Assert — injection strings must parse normally without side effects
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.amount, 100.0)
    }
}
