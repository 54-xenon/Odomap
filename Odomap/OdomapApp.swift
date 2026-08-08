//
//  OdomapApp.swift
//  Odomap
//
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct OdomapApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Ride.self)
    }
}
