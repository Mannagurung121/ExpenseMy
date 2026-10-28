import Foundation
import SwiftUI

@Observable
final class UserManager {
    static let shared = UserManager()

    var phoneNumber: String {
        get { UserDefaults.standard.string(forKey: "phoneNumber") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "phoneNumber") }
    }

    var userName: String {
        get { UserDefaults.standard.string(forKey: "userName") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "userName") }
    }

    var userEmail: String {
        get { UserDefaults.standard.string(forKey: "userEmail") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "userEmail") }
    }

    var userDOB: Date {
        get {
            let timestamp = UserDefaults.standard.double(forKey: "userDOB")
            return timestamp == 0 ? Date() : Date(timeIntervalSince1970: timestamp)
        }
        set {
            UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: "userDOB")
        }
    }

    var initials: String {
        let parts = userName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(userName.prefix(2)).uppercased()
    }
}
