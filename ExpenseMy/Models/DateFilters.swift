//
//  DateFilters.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 06/05/26.
//

import Foundation

enum DateFilter: String, CaseIterable {
    case today     = "Today"
    case week      = "This Week"
    case month     = "This Month"
    case year      = "This Year"
    case all       = "All Time"

    var dateRange: (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let start = cal.startOfDay(for: now)
            let end   = cal.date(byAdding: .day, value: 1, to: start)!
            return (start, end)

        case .week:
            let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let end   = cal.date(byAdding: .day, value: 7, to: start)!
            return (start, end)

        case .month:
            let start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            let end   = cal.date(byAdding: .month, value: 1, to: start)!
            return (start, end)

        case .year:
            let start = cal.date(from: cal.dateComponents([.year], from: now))!
            let end   = cal.date(byAdding: .year, value: 1, to: start)!
            return (start, end)

        case .all:
            return (Date.distantPast, Date.distantFuture)
        }
    }
}
