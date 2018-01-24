//
//  NotificationMenuView.swift
//  USSoccer
//
//  Created by Jared Sobol on 12/4/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import UserNotifications

class NotificationMenuView: UIView, UITableViewDataSource, UITableViewDelegate {
    var currentUser = Auth.auth().currentUser
//    let isAnonymous = user!.isAnonymous  // true
//    let uid = user!.uid
//    let usersRef = ref.child(user.uid
    var twoDayBool = false
    var oneDayBool = false
    var twoHourBool = false
    var oneHourBool = false
    var halfHourBool = false
    var notificationAuthorizationStatus : UNAuthorizationStatus = .notDetermined
    var currentUserSettings : Person? {
        return CoreDataService.shared.fetchPerson()
    }
    
    var teamsArray = ["ALL TEAMS", "MNT", "WNT", "U-23 MNT", "U-23 WNT", "U-20 MNT", "U-20 WNT", "U-19 MNT", "U-19 WNT", "U-18 MNT", "U-18 WNT", "U-17 MNT", "U-17 WNT", "U-16 MNT", "U-16 WNT","U-15 MNT", "U-15 WNT"]
    var selectedTeams = [String : Bool]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teamsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TeamTVC", for: indexPath) as? TeamsTVC else {
            fatalError("The Cell Failed to Deque")
        }
        let teamTitle = teamsArray[indexPath.row]
        cell.teamTitle.text = teamTitle
        
        
        if let isSelected = selectedTeams[teamTitle] {
            cell.configure(selected: isSelected)
        } else {
            
            followingRef.child(teamsArray[indexPath.row]).observeSingleEvent(of: .value) { (snapshot) in
                let value = snapshot.value as? NSDictionary
                if value == nil {
                    cell.configure(selected: false)
                    self.selectedTeams[teamTitle] = false
                } else {
                    if let userFollowing = value![self.currentUser!.uid] {
                        if userFollowing as! Bool {
                            cell.configure(selected: true)
                            self.selectedTeams[teamTitle] = true
                        } else {
                            cell.configure(selected: false)
                            self.selectedTeams[teamTitle] = false
                        }
                    } else {
                        cell.configure(selected: false)
                        self.selectedTeams[teamTitle] = false
                    }
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let teamTitle = self.teamsArray[indexPath.row]
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationAuthorizationStatus = settings.authorizationStatus
            
            DispatchQueue.main.async {
                if self.currentUserSettings?.firstTimeClickingteam == true {
                    messageAlert(title: "\(teamTitle) Notifications Set", message: "Your are now following \(teamTitle). \n You will recieve notifications for every game this team has in the future. \n Click \(teamTitle) to turn this off" , from: nil)
                    self.currentUserSettings?.setValue(false, forKey: "firstTimeClickingteam")
                    CoreDataService.shared.saveContext()
                }
                if self.notificationAuthorizationStatus != .authorized {
                    messageAlert(title: "Notifications Permission Required", message: "In order to update notification settings, notification permission is required. \n\n Please go to your setting and turn on notifications for USSoccer.", from: nil)
                    print("notifications are NOT enabled")
                } else {
                    
                    if ConnectionCheck.isConnectedToNetwork() {
                        
                        let followingTeamRef = followingRef.child(teamTitle).child(self.currentUser!.uid)
                        
                        var isSelected = self.selectedTeams[teamTitle] ?? false
                        // Flip
                        isSelected = !isSelected
                        self.selectedTeams[teamTitle] = isSelected
                        if isSelected {
                            followingTeamRef.setValue(true)
                        } else {
                            followingTeamRef.removeValue()
                        }
                        
                        tableView.reloadData()
                        
                    } else {
                        messageAlert(title: "No Internet Connection", message: "Internet connection is required to update team notifications.", from: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func twoDaySwitch(_ sender: UISwitch) {
        if currentUserSettings?.firstTimeTogglingNotificationSettings == true {
            messageAlert(title: "Notifications Setting Updated", message: "You have updated, one of your settings. \n if the toggle is blue the setting is on, if the toggle is white the settings is off.", from: nil)
            currentUserSettings?.setValue(false, forKey: "firstTimeTogglingNotificationSettings")
            CoreDataService.shared.saveContext()
        }
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationAuthorizationStatus = settings.authorizationStatus
            
            DispatchQueue.main.async {
                
                if self.notificationAuthorizationStatus != .authorized {
                    messageAlert(title: "Notifications Permission Required", message: "In order to update notification settings, notification permission is required. \n\n Please go to your setting and turn on notifications for USSoccer.", from: nil)
                    print("notifications are NOT enabled")
                } else {
                    if ConnectionCheck.isConnectedToNetwork() {
                        self.twoDayBool = sender.isOn
                        ref.child("users").child((self.currentUser?.uid)!).child("notificationSettings").updateChildValues(["TwoDayNotification": self.twoDayBool])
                    } else {
                        messageAlert(title: "No Internet Connection", message: "Internet connection is required to update team notifications.", from: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func oneDaySwitch(_ sender: UISwitch) {
        if currentUserSettings?.firstTimeTogglingNotificationSettings == true {
            messageAlert(title: "Notifications Setting Updated", message: "You have updated, one of your settings. \n if the toggle is blue the setting is on, if the toggle is white the settings is off.", from: nil)
            currentUserSettings?.setValue(false, forKey: "firstTimeTogglingNotificationSettings")
            CoreDataService.shared.saveContext()
        }
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationAuthorizationStatus = settings.authorizationStatus
            
            DispatchQueue.main.async {
                
                if self.notificationAuthorizationStatus != .authorized {
                    messageAlert(title: "Notifications Permission Required", message: "In order to update notification settings, notification permission is required. \n\n Please go to your setting and turn on notifications for USSoccer.", from: nil)
                    print("notifications are NOT enabled")
                } else {
                    if ConnectionCheck.isConnectedToNetwork() {
                        self.oneDayBool = sender.isOn
                        ref.child("users").child((self.currentUser?.uid)!).child("notificationSettings").updateChildValues(["OneDayNotification": self.oneDayBool])
                    } else {
                        messageAlert(title: "No Internet Connection", message: "Internet connection is required to update team notifications.", from: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func twoHourSwitch(_ sender: UISwitch) {
        if currentUserSettings?.firstTimeTogglingNotificationSettings == true {
            messageAlert(title: "Notifications Setting Updated", message: "You have updated, one of your settings. \n if the toggle is blue the setting is on, if the toggle is white the settings is off.", from: nil)
            currentUserSettings?.setValue(false, forKey: "firstTimeTogglingNotificationSettings")
            CoreDataService.shared.saveContext()
        }
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationAuthorizationStatus = settings.authorizationStatus
            
            DispatchQueue.main.async {
                
                if self.notificationAuthorizationStatus != .authorized {
                    messageAlert(title: "Notifications Permission Required", message: "In order to update notification settings, notification permission is required. \n\n Please go to your setting and turn on notifications for USSoccer.", from: nil)
                    print("notifications are NOT enabled")
                } else {
                    if ConnectionCheck.isConnectedToNetwork() {
                        self.twoHourBool = sender.isOn
                        ref.child("users").child((self.currentUser?.uid)!).child("notificationSettings").updateChildValues(["TwoHourNotification": self.twoHourBool])
                    } else {
                        messageAlert(title: "No Internet Connection", message: "Internet connection is required to update team notifications.", from: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func oneHourSwitch(_ sender: UISwitch) {
        if currentUserSettings?.firstTimeTogglingNotificationSettings == true {
            messageAlert(title: "Notifications Setting Updated", message: "You have updated, one of your settings. \n if the toggle is blue the setting is on, if the toggle is white the settings is off.", from: nil)
            currentUserSettings?.setValue(false, forKey: "firstTimeTogglingNotificationSettings")
            CoreDataService.shared.saveContext()
        }
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationAuthorizationStatus = settings.authorizationStatus
            
            DispatchQueue.main.async {
                
                if self.notificationAuthorizationStatus != .authorized {
                    messageAlert(title: "Notifications Permission Required", message: "In order to update notification settings, notification permission is required. \n\n Please go to your setting and turn on notifications for USSoccer.", from: nil)
                    print("notifications are NOT enabled")
                } else {
                    if ConnectionCheck.isConnectedToNetwork() {
                        self.oneHourBool = sender.isOn
                        ref.child("users").child((self.currentUser?.uid)!).child("notificationSettings").updateChildValues(["OneHourNotification": self.oneHourBool])
                    } else {
                        messageAlert(title: "No Internet Connection", message: "Internet connection is required to update team notifications.", from: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func halfHourSwitch(_ sender: UISwitch) {
        if currentUserSettings?.firstTimeTogglingNotificationSettings == true {
            messageAlert(title: "Notifications Setting Updated", message: "You have updated, one of your settings. \n if the toggle is blue the setting is on, if the toggle is white the settings is off.", from: nil)
            currentUserSettings?.setValue(false, forKey: "firstTimeTogglingNotificationSettings")
            CoreDataService.shared.saveContext()
        }
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationAuthorizationStatus = settings.authorizationStatus
            
            DispatchQueue.main.async {
                
                if self.notificationAuthorizationStatus != .authorized {
                    messageAlert(title: "Notifications Permission Required", message: "In order to update notification settings, notification permission is required. \n\n Please go to your setting and turn on notifications for USSoccer.", from: nil)
                    print("notifications are NOT enabled")
                } else {
                    if ConnectionCheck.isConnectedToNetwork() {
                        self.halfHourBool = sender.isOn
                        ref.child("users").child((self.currentUser?.uid)!).child("notificationSettings").updateChildValues(["HalfHourNotification": self.halfHourBool])
                    } else {
                        messageAlert(title: "No Internet Connection", message: "Internet connection is required to update team notifications.", from: nil)
                    }
                }
            }
        }
    }
}
