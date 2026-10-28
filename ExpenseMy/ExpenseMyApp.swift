//
//  ExpenseMyApp.swift
//  ExpenseMy
//

import SwiftUI
import SwiftData
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        return true
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("APNS Error:", error.localizedDescription)
    }
}

@main
struct ExpenseMyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear {
                    importPendingTransactions()
                }
        }
        .modelContainer(for: Transaction.self)
    }

    @MainActor
    private func importPendingTransactions() {
        let pending = SharedDataManager.getPendingDTOs()
        guard !pending.isEmpty else { return }

        do {
            let container = try ModelContainer(for: Transaction.self)
            let context = ModelContext(container)

            for dto in pending {
                context.insert(dto.toTransaction())
            }

            try context.save()
            SharedDataManager.clearPendingTransactions()
        } catch {
            print("Import error: \(error)")
        }
    }
}
