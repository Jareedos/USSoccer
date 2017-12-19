//
//  AppDelegate.swift
//  USSoccer
//
//  Created by Jared Sobol on 10/3/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit
import Firebase
import CoreData
import OneSignal

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]
        
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: "28bbbff3-5e9e-468c-b99d-beb9d034f404",
                                        handleNotificationAction: nil,
                                        settings: onesignalInitSettings)
        
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
        
        Auth.auth().signInAnonymously { (user: User?, error: Error?) in
            
            if let user = user {
                
                
                // Recommend moving the below line to prompt for push after informing the user about
                //   how your app will use them.
                OneSignal.promptForPushNotifications(userResponse: { accepted in
                    print("User accepted notifications: \(accepted)")
                    
                    if accepted {
                        
                        OneSignal.setSubscription(true)
                        
                        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
                        
                        let hasPrompted = status.permissionStatus.hasPrompted
                        print("hasPrompted = \(hasPrompted)")
                        let userStatus = status.permissionStatus.status
                        print("userStatus = \(userStatus)")
                        
                        let isSubscribed = status.subscriptionStatus.subscribed
                        print("isSubscribed = \(isSubscribed)")
                        let userSubscriptionSetting = status.subscriptionStatus.userSubscriptionSetting
                        print("userSubscriptionSetting = \(userSubscriptionSetting)")
                        
                        
                        // This is your device's identification within OneSignal
                        guard let userID = status.subscriptionStatus.userId else { return }
                        CoreDataService.shared.savePerson(userID: userID)
                        if CoreDataService.shared.fetchPerson().userID != userID {
                            print("I DIDNT WORK FUCK FUCK FUCK FUCK FUCK")
                            print("userID = \(userID)")
                            let pushToken = status.subscriptionStatus.pushToken
                            print("pushToken = \(pushToken ?? "")")
                            
                            
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
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //Core Data
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "USSoccer")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

