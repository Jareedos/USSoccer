//
//  NotificationService.swift
//  USSoccer
//
//  Created by Jared Sobol on 12/5/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import Foundation
import OneSignal
import Firebase

class NotificationService: UNNotificationServiceExtension, UNUserNotificationCenterDelegate, OSSubscriptionObserver {
    static let shared = NotificationService()
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var receivedRequest: UNNotificationRequest!
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.receivedRequest = request;
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            OneSignal.didReceiveNotificationExtensionRequest(self.receivedRequest, with: self.bestAttemptContent)
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            OneSignal.serviceExtensionTimeWillExpireRequest(self.receivedRequest, with: self.bestAttemptContent)
            contentHandler(bestAttemptContent)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let data = response.notification.request.content.userInfo as? [String : Any] {
            NavigationService.shared.handle(notificationData: data)
        }
    }
    
    // MARK: - OSSubscriptionObserver
    
    func onOSSubscriptionChanged(_ stateChanges: OSSubscriptionStateChanges!) {
        
        guard let user = Auth.auth().currentUser else { return }
        let userRef = Database.database().reference().child("users").child(user.uid)
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        
        if let userID = status.subscriptionStatus.userId {
            if let person = CoreDataService.shared.fetchPerson(), person.userID != userID {
                // Set the one signal id
                userRef.child("oneSignalIds").child(userID).setValue(true)
            }
        }
    }
}
