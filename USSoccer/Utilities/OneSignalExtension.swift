//
//  OneSignalExtension.swift
//  USSoccer
//
//  Created by Jared Sobol on 1/27/18.
//  Copyright © 2018 Appmaker. All rights reserved.
//

import Foundation
import OneSignal
import CoreData
import FirebaseAuth
import FirebaseDatabase

extension OneSignal {
    
    static func promptPushNotificationAlert() {
        
        guard let user = Auth.auth().currentUser else { return }
        
        // Recommend moving the below line to prompt for push after informing the user about
        //   how your app will use them.
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            
            if accepted {
                
                OneSignal.setSubscription(true)
                
                let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
//                let hasPrompted = status.permissionStatus.hasPrompted
//                let userStatus = status.permissionStatus.status
//                let isSubscribed = status.subscriptionStatus.subscribed
//                let userSubscriptionSetting = status.subscriptionStatus.userSubscriptionSetting

                // This is your device's identification within OneSignal
                guard let userID = status.subscriptionStatus.userId else { return }
                if let person = CoreDataService.shared.fetchPerson(), person.userID != userID {
                    //                           let pushToken = status.subscriptionStatus.pushToken
                    let userRef = Database.database().reference().child("users").child(user.uid)
                    // Set the one signal id
                    
                    userRef.child("oneSignalIds").child(userID).setValue(true)
                    
                    
                    // Save the push notification settings
                    let dict: [String: Bool] = ["TwoDayNotification": false, "OneDayNotification": false, "TwoHourNotification": true, "OneHourNotification": false, "HalfHourNotification": false]
                    userRef.child("notificationSettings").setValue(dict)
                    
                    // Set the following of the teams
                    let teams = CoreDataService.shared.fetchTeams()
                    for team in teams {
                        if let key = team.firebaseKey() {
                            let teamFollowingRef = followingRef.child(key).child(user.uid)
                            if team.notifications {
                                teamFollowingRef.setValue(true)
                            } else {
                                teamFollowingRef.removeValue()
                            }
                        }
                    }
                }
            }
        })
    }
    
}
