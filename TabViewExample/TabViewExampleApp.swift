//
//  TabViewExampleApp.swift
//  TabViewExample
//
//  Created by Vladimir Amiorkov on 31.01.25.
//

import SwiftUI

@main
struct TabViewExampleApp: App {
    let persistenceController = PersistenceController.shared
    let userNotificationCenterService = UserNotificationCenterService.shared
    
    init() {
        userNotificationCenterService.setupCenterDelegate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
