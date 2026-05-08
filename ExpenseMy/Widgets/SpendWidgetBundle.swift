//
//  SpendWidgetBundle.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 07/05/26.
//

import WidgetKit
import SwiftUI
import Combine

@main
struct SpendWidgetBundle: WidgetBundle {
    var body: some Widget {
        SmallSpendWidget()
        MediumSpendWidget()
    }
}
