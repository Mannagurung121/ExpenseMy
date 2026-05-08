//
//  SmsParser.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 06/05/26.
//

// SMSParser.swift
import Foundation

struct SMSParser {

    static func parse(_ sms: String) -> Transaction? {
        guard isTransactionSMS(sms) else { return nil }

        guard let amount = extractAmount(from: sms) else { return nil }
        let type     = extractType(from: sms)
        let merchant = extractMerchant(from: sms)
        let bank     = extractBank(from: sms)
        let date     = extractDate(from: sms) ?? Date()
        let category = CategoryClassifier.classify(merchant: merchant, rawText: sms)

        return Transaction(
            amount: amount,
            type: type,
            merchant: merchant,
            category: category,
            bank: bank,
            date: date,
            rawSMS: sms
        )
    }

    // MARK: - OTP / junk filter
    private static func isTransactionSMS(_ text: String) -> Bool {
        let lower = text.lowercased()

        let hasAmount = extractAmount(from: text) != nil

        let otpKeywords = ["otp", "one time password", "verification code",
                           "do not share", "not share", "never share"]
        let isOTP = otpKeywords.contains { lower.contains($0) }

        // "sent" add kiya — Kotak format ke liye
        let transactionKeywords = ["debited", "credited", "debit", "credit",
                                   "spent", "paid", "withdrawn", "deposit",
                                   "transferred", "purchase", "transaction",
                                   "sent"]
        let hasTransaction = transactionKeywords.contains { lower.contains($0) }

        return hasAmount && !isOTP && hasTransaction
    }

    // MARK: - Amount
    static func extractAmount(from text: String) -> Double? {
        let patterns = [
            #"(?:Rs\.?|INR)\s*([\d,]+(?:\.\d{1,2})?)"#,
            #"([\d,]+(?:\.\d{1,2})?)\s*(?:Rs|INR)"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern,
                                                    options: .caseInsensitive),
               let match = regex.firstMatch(in: text,
                                            range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let cleaned = String(text[range]).replacingOccurrences(of: ",", with: "")
                if let amount = Double(cleaned), amount > 0 {
                    return amount
                }
            }
        }
        return nil
    }

    // MARK: - Debit or Credit
    static func extractType(from text: String) -> TransactionType {
        let lower = text.lowercased()
        let creditWords = ["credited", "credit", "received", "deposit",
                           "refund", "cashback", "added", "reversed"]
        if creditWords.contains(where: { lower.contains($0) }) {
            return .credit
        }
        return .debit
    }

    // MARK: - Merchant name
    static func extractMerchant(from text: String) -> String {

        let upiPatterns = [
            #"(?:to VPA|VPA[:/])\s*([a-zA-Z0-9-]+)[@.]"#,  // to VPA zomato@paytm
            #"to\s+([a-zA-Z0-9][a-zA-Z0-9-]*?)[@]"#,        // to zomato-order@ptybl ← naya
            #"UPI[:/\-]\s*([A-Z][A-Z0-9]+)"#,               // UPI-SWIGGY
            #"(?:to|towards)\s+([A-Z][a-zA-Z0-9\s]{2,20})\s+(?:via|on|ref)"#
        ]

        for pattern in upiPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern,
                                                    options: .caseInsensitive),
               let match = regex.firstMatch(in: text,
                                            range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                // "zomato-order" → "zomato" (hyphen ke pehle wala part lo)
                var name = String(text[range])
                name = name.components(separatedBy: "-").first ?? name
                name = name.trimmingCharacters(in: .whitespaces)
                if name.count >= 2 {
                    return name.capitalized
                }
            }
        }

        // "at MERCHANT on" — card transactions
        let atPattern = #"at\s+([A-Z][A-Za-z0-9\s]{1,25}?)\s+on\s"#
        if let regex = try? NSRegularExpression(pattern: atPattern),
           let match = regex.firstMatch(in: text,
                                        range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range]).trimmingCharacters(in: .whitespaces)
        }

        // "Info: UPI-MERCHANTNAME"
        let infoPattern = #"Info:\s*UPI[- ]([A-Z]{2,20})"#
        if let regex = try? NSRegularExpression(pattern: infoPattern),
           let match = regex.firstMatch(in: text,
                                        range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range]).capitalized
        }

        return "Unknown"
    }

    // MARK: - Bank name
    static func extractBank(from text: String) -> String {
        let bankMap: [(keywords: [String], name: String)] = [
            (["sbi", "state bank"],         "SBI"),
            (["hdfc"],                       "HDFC"),
            (["icici"],                      "ICICI"),
            (["axis"],                       "Axis Bank"),
            (["kotak"],                      "Kotak"),
            (["pnb", "punjab national"],     "PNB"),
            (["bob", "bank of baroda"],      "Bank of Baroda"),
            (["canara"],                     "Canara Bank"),
            (["yes bank"],                   "Yes Bank"),
            (["indusind"],                   "IndusInd"),
            (["paytm"],                      "Paytm Bank"),
            (["airtel"],                     "Airtel Bank"),
        ]
        let lower = text.lowercased()
        for entry in bankMap {
            if entry.keywords.contains(where: { lower.contains($0) }) {
                return entry.name
            }
        }
        return "Unknown Bank"
    }

    // MARK: - Date
    static func extractDate(from text: String) -> Date? {
        let formats = [
            "dd-MM-yy",
            "dd/MM/yyyy",
            "dd-MM-yyyy",
            "dd-MMM-yy",
            "dd-MMM-yyyy",
            "dd MMM yyyy",
            "d-MM-yy",
        ]

        let datePattern = #"\b(\d{1,2}[-/\s]\w{2,9}[-/\s]\d{2,4})\b"#
        guard let regex = try? NSRegularExpression(pattern: datePattern),
              let match = regex.firstMatch(in: text,
                                           range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }

        let dateStr = String(text[range])
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateStr) {
                return date
            }
        }
        return nil
    }
}
