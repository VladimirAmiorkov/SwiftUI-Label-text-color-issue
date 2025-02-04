//
//  UserNotificationCenterService.swift
//  TabViewExample
//
//  Created by Vladimir Amiorkov on 4.02.25.
//

import Foundation
import Foundation
import UIKit

// MARK: Main class
class UserNotificationCenterService: NSObject {
    
    static let shared = UserNotificationCenterService()
    
    private let persistenceController = PersistenceController.shared
    private var categoryIdentifier: String {
        "test"
    }
    private var actionIdentifier: String {
        "addAction"
    }
    
    private var userNotificationCenter: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }
    
    private var options: UNAuthorizationOptions {
        [.alert, .badge, .sound]
    }
    
    func setupCenterDelegate() {
        print("setupCenterDelegate")
        
        var categories: Set<UNNotificationCategory> = []
        categories.insert(getAddCategories())
        
        userNotificationCenter.setNotificationCategories(categories)
        
        userNotificationCenter.delegate = self
    }
    
    private func addItem() {
        let viewContext = persistenceController.container.viewContext
        let newItem = Item(context: viewContext)
        newItem.timestamp = Date()

        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func requestAuthorization(completionHandler: @escaping ((Bool, Error?) -> Void)) {
        userNotificationCenter.requestAuthorization(options: options) { granted, error in
            guard error == nil else {
                print("requestAuthorization(completionHandler:) - error \(String(describing: error?.localizedDescription))")
                completionHandler(false, error)
                return
            }
            
            guard granted else {
                print("requestAuthorization(completionHandler:) - granted: '\(granted)'")
                completionHandler(granted, error)
                return
            }
            
            print("granted: '\(granted)'")
            completionHandler(true, error)
        }
    }
    
    func scheduleNotification() {
        requestAuthorization { [weak self] granted, error in
            guard granted && error == nil, let self = self else { return }
            
            let triggerDate = Date().addingTimeInterval(5)
            let dateComponents = Calendar.current.dateComponents([.hour, .minute, .second, .weekday], from: triggerDate)
            let content = UNMutableNotificationContent()
            content.title = "Test title"
            content.body = "test body"
            content.badge = 1
            content.categoryIdentifier = categoryIdentifier
            content.sound = .default
            
            content.userInfo = [
                "notificationBody": content.body,
                "notificationTitle": content.title,
                "categoryIdentifier": content.categoryIdentifier
            ]
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            self.userNotificationCenter.add(request)
        }
    }
    
    private func getAddCategories() -> UNNotificationCategory {
        let add = UNNotificationAction(identifier: actionIdentifier,
                                               title: "Add",
                                               options: [],
                                               icon: UNNotificationActionIcon(systemImageName: "plus"))
        
        return UNNotificationCategory(identifier: categoryIdentifier,
                                      actions: [add],
                                      intentIdentifiers: [],
                                      hiddenPreviewsBodyPlaceholder: "Add",
                                      options: .customDismissAction)
    }
    
    private func clearIconBadgeIfNeeded(completion: @escaping () -> Void) {
        print("clearIconBadgeIfNeeded(completion:)")
        
        /// This is the only way to make calling `clearIconBadgeIfNeeded` from `userNotificationCenter(_:didReceive:withCompletionHandler:)` work.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.userNotificationCenter.getDeliveredNotifications { notifications in
                print("getDeliveredNotifications")
                guard notifications.isEmpty else {
                    DispatchQueue.main.async {
                        print("clearIconBadgeIfNeeded - DROPPING due to delivered present notification")
                        completion()
                    }
                    
                    return
                }
                
                DispatchQueue.main.async {
                    print("clearIconBadgeIfNeeded - set badge to 0")
                    
                    UNUserNotificationCenter.current().setBadgeCount(0)
                    
                    completion()
                }
            }
        }
    }
    
    private func clearIconBadgeIfNeeded() async {
        print("clearIconBadgeIfNeeded()")

        /// This is the only way to make calling `clearIconBadgeIfNeeded` from `userNotificationCenter(_:didReceive:withCompletionHandler:)` work.
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds delay

        let notifications = await userNotificationCenter.deliveredNotifications()

        print("getDeliveredNotifications")
        
        guard notifications.isEmpty else {
            print("clearIconBadgeIfNeeded - DROPPING due to delivered present notification")
            return
        }

        print("clearIconBadgeIfNeeded - set badge to 0")
        
        try? await UNUserNotificationCenter.current().setBadgeCount(0)
    }

}

// MARK: UNUserNotificationCenterDelegate
extension UserNotificationCenterService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .list]
    }
    
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        print("userNotificationCenter(_:didReceive:) async - called")
        
        switch response.actionIdentifier {
        case actionIdentifier:
            addItem()
        default:
            break
        }

        // Even if `clearIconBadgeIfNeeded` is not called, same issue is observed.
        await clearIconBadgeIfNeeded()
    }
    
    // Same issue when using non async variant, as soon as the `completionHandler` is called the app refreshed in the background and leads to the Label text color issue.
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        print("userNotificationCenter(_:didReceive:withCompletionHandler:) - called")
//        
//        switch response.actionIdentifier {
//        case actionIdentifier:
//            addItem()
//        default:
//            break
//        }
//        
//        // Even if `completionHandler` is directly called without `clearIconBadgeIfNeeded`, same issue is observed.
//        clearIconBadgeIfNeeded {
//            completionHandler()
//        }
//    }
}
