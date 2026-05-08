//
//  Category.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 06/05/26.
//

import Foundation

struct CategoryClassifier {

    static let keywordMap: [Category: [String]] = [
        .food: [
            "swiggy", "zomato", "dominos", "domino", "kfc", "mcdonalds",
            "mcdonald", "blinkit", "dunzo", "zepto", "bigbasket", "grofers",
            "restaurant", "cafe", "dhaba", "haldiram", "biryani", "pizza",
            "burger", "food", "eat", "kitchen", "canteen", "mess", "hotel",
            "starbucks", "subway", "dairy", "milk", "bread", "bakery",
            "chaayos", "barista", "instamartexpress", "jiomart"
        ],
        .transport: [
            "ola", "uber", "rapido", "metro", "irctc", "redbus", "abhibus",
            "makemytrip", "goibibo", "indigo", "spicejet", "airindia",
            "vistara", "petrol", "fuel", "bpcl", "hpcl", "iocl", "toll",
            "fastag", "parking", "cab", "taxi", "auto", "yatra", "ixigo"
        ],
        .recharge: [
            "airtel", "jio", "vodafone", "vi ", " vi", "bsnl", "mtnl",
            "tatasky", "tata sky", "dishtv", "dish tv", "sundirect",
            "recharge", "prepaid", "postpaid", "electricity", "bescom",
            "tpddl", "msedcl", "water", "gas", "bill payment", "billpay",
            "d2h", "videocon", "broadband", "fibernet"
        ],
        .shopping: [
            "amazon", "flipkart", "myntra", "meesho", "snapdeal", "ajio",
            "nykaa", "reliance", "dmart", "more supermarket", "big bazaar",
            "shoppers stop", "westside", "h&m", "zara", "decathlon",
            "pepperfry", "urban ladder", "firstcry", "hopscotch",
            "lenskart", "purplle", "mamaearth", "boat", "noise"
        ],
        .entertainment: [
            "netflix", "spotify", "prime", "hotstar", "disney", "zee5",
            "sonyliv", "voot", "youtube", "gaana", "jiosaavn", "wynk",
            "bookmyshow", "inox", "pvr", "paytm movies", "mxplayer",
            "hungama", "apple music", "audible"
        ],
        .healthcare: [
            "pharmacy", "hospital", "clinic", "apollo", "netmeds", "1mg",
            "medlife", "doctor", "medical", "lab", "diagnostic", "tata1mg",
            "pharmeasy", "healthians", "thyrocare", "srl", "practo",
            "medplus", "wellness", "optician", "chemist", "dentist"
        ],
        .rent: [
            "rent", "society", "maintenance", "housing", "property",
            "flat", "apartment", "pg", "hostel", "nobroker", "magicbricks",
            "99acres", "commonfloor", "nestaway", "stanza"
        ]
    ]

    static func classify(merchant: String?, rawText: String) -> Category {
        let searchText = "\(merchant ?? "") \(rawText)".lowercased()
        for (category, keywords) in keywordMap {
            if keywords.contains(where: { searchText.contains($0) }) {
                return category
            }
        }
        return .uncategorized
    }
}
