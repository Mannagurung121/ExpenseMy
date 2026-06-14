//
//  CategoryClassifierTests.swift
//  ExpenseMyTests
//

import XCTest
@testable import ExpenseMy

final class CategoryClassifierTests: XCTestCase {

    func testSwiggyMapsToFood() {
        // Arrange
        let merchant = "Swiggy"

        // Act
        let category = CategoryClassifier.classify(merchant: merchant, rawText: "")

        // Assert
        XCTAssertEqual(category, .food)
    }

    func testZomatoMapsToFood() {
        // Arrange
        let merchant = "Zomato"

        // Act
        let category = CategoryClassifier.classify(merchant: merchant, rawText: "")

        // Assert
        XCTAssertEqual(category, .food)
    }

    func testUberMapsToTransport() {
        // Arrange
        let merchant = "Uber"

        // Act
        let category = CategoryClassifier.classify(merchant: merchant, rawText: "")

        // Assert
        XCTAssertEqual(category, .transport)
    }

    func testOlaMapsToTransport() {
        // Arrange
        let merchant = "Ola"

        // Act
        let category = CategoryClassifier.classify(merchant: merchant, rawText: "")

        // Assert
        XCTAssertEqual(category, .transport)
    }

    func testAirtelMapsToRecharge() {
        // Arrange
        let merchant = "Airtel"

        // Act
        let category = CategoryClassifier.classify(merchant: merchant, rawText: "")

        // Assert
        XCTAssertEqual(category, .recharge)
    }

    func testJioMapsToRecharge() {
        // Arrange
        let merchant = "Jio"

        // Act
        let category = CategoryClassifier.classify(merchant: merchant, rawText: "")

        // Assert
        XCTAssertEqual(category, .recharge)
    }

    func testAmazonMapsToShopping() {
        // Arrange
        let merchant = "Amazon"

        // Act
        let category = CategoryClassifier.classify(merchant: merchant, rawText: "")

        // Assert
        XCTAssertEqual(category, .shopping)
    }

    func testFlipkartMapsToShopping() {
        // Arrange
        let merchant = "Flipkart"

        // Act
        let category = CategoryClassifier.classify(merchant: merchant, rawText: "")

        // Assert
        XCTAssertEqual(category, .shopping)
    }

    func testNetflixMapsToEntertainment() {
        // Arrange
        let merchant = "Netflix"

        // Act
        let category = CategoryClassifier.classify(merchant: merchant, rawText: "")

        // Assert
        XCTAssertEqual(category, .entertainment)
    }

    func testApolloMapsToHealthcare() {
        // Arrange
        let merchant = "Apollo"

        // Act
        let category = CategoryClassifier.classify(merchant: merchant, rawText: "")

        // Assert
        XCTAssertEqual(category, .healthcare)
    }

    func testUnknownMerchantMapsToUncategorized() {
        // Arrange
        let merchant = "XYZStore123"

        // Act
        let category = CategoryClassifier.classify(merchant: merchant, rawText: "")

        // Assert
        XCTAssertEqual(category, .uncategorized)
    }

    func testCaseInsensitivity() {
        // Arrange
        let variants = ["SWIGGY", "swiggy", "Swiggy"]

        // Act & Assert — classify lowercases the search text internally
        for variant in variants {
            let category = CategoryClassifier.classify(merchant: variant, rawText: "")
            XCTAssertEqual(category, .food, "Expected .food for merchant '\(variant)'")
        }
    }

    func testEmptyStringMapsToUncategorized() {
        // Arrange
        let merchant = ""

        // Act
        let category = CategoryClassifier.classify(merchant: merchant, rawText: "")

        // Assert
        XCTAssertEqual(category, .uncategorized)
    }

    func testMerchantWithExtraWhitespace() {
        // Arrange — leading and trailing spaces should still match keyword
        let merchant = " Swiggy "

        // Act
        let category = CategoryClassifier.classify(merchant: merchant, rawText: "")

        // Assert
        XCTAssertEqual(category, .food)
    }
}
