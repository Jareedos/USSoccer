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
import OneSignal

class NotificationMenuView: UIView, UITableViewDataSource, UITableViewDelegate {
    var currentUser = Auth.auth().currentUser
    
    var currentTeam : Team?
    var notificationAuthorizationStatus : UNAuthorizationStatus = .notDetermined
    var currentUserSettings : Person? {
        return CoreDataService.shared.fetchPerson()
    }
    
    var teamsArray = ["ALL TEAMS", "MNT", "WNT", "U-23 MNT", "U-23 WNT", "U-20 MNT", "U-20 WNT", "U-19 MNT", "U-19 WNT", "U-18 MNT", "U-18 WNT", "U-17 MNT", "U-17 WNT", "U-16 MNT", "U-16 WNT","U-15 MNT", "U-15 WNT"]
    private var selectedTeams = [String : Bool]()
    
    @IBOutlet weak var tableView: UITableView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let uid = Auth.auth().currentUser?.uid {
            
            for team in teamsArray {
                followingRef.child(team).child(uid).observeSingleEvent(of: .value) { (snapshot) in
                    DispatchQueue.main.async {
                        let value = (snapshot.value as? Bool) ?? false
                        self.selectedTeams[team] = value
                        self.tableView?.reloadData()
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teamsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TeamTVC", for: indexPath) as? TeamsTVC else {
            fatalError("The Cell Failed to Deque")
        }
        
        let teamTitle = teamsArray[indexPath.row]
        cell.teamTitle.text = teamTitle
        
        let isSelected = selectedTeams[teamTitle] ?? false
        cell.configure(selected: isSelected)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let teamTitle = self.teamsArray[indexPath.row]
        let teams = CoreDataService.shared.fetchTeams()
        for team in teams {
            if stringTrimmer(stringToTrim: teamTitle)?.uppercased() == stringTrimmer(stringToTrim: team.title)?.uppercased() {
                currentTeam = team
            }
        }
        
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
                } else {
                    
                    if ConnectionCheck.isConnectedToNetwork() {
                        // Toggle selection
                        
                        let followingTeamRef = followingRef.child(teamTitle).child(self.currentUser!.uid)
                        
                        var isSelected = self.selectedTeams[teamTitle] ?? false
                        
                        
                        // Flip
                        isSelected = !isSelected
                        self.selectedTeams[teamTitle] = isSelected
                        
                        // Update Core data
                        if isSelected {
                            followingTeamRef.setValue(true)
                            //This should save if the user turned on Team notificicaitons
                            self.currentTeam?.setValue(true, forKey: "notifications")
                            CoreDataService.shared.saveContext()
                        } else {
                            followingTeamRef.removeValue()
                            
                            self.currentTeam?.setValue(false, forKey: "notifications")
                            CoreDataService.shared.saveContext()
                        }
                        
                        // Update OneSignal
                        self.updateSubscriptions()
                        
                        tableView.reloadData()
                        
                        
                    } else {
                        messageAlert(title: "No Internet Connection", message: "Internet connection is required to update team notifications.", from: nil)
                    }
                }
            }
        }
    }
    
    func updateSubscriptions() {
        // Create a list of time interval toggles
        ReminderService.shared.updateSubsription(selectedTeams: selectedTeams)
    }
    
    @IBAction func twoDaySwitch(_ sender: UISwitch) {
        if currentUserSettings?.firstTimeTogglingNotificationSettings == true {
            messageAlert(title: "Notifications Setting Updated", message: "You have updated one of your settings. \n If the toggle is blue the setting is on, if the toggle is white the setting is off.", from: nil)
            currentUserSettings?.setValue(false, forKey: "firstTimeTogglingNotificationSettings")
            CoreDataService.shared.saveContext()
        }
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationAuthorizationStatus = settings.authorizationStatus
            
            DispatchQueue.main.async {
                
                if self.notificationAuthorizationStatus != .authorized {
                    messageAlert(title: "Notifications Permission Required", message: "In order to update notification settings, notification permission is required. \n\n Please go to your setting and turn on notifications for USSoccer.", from: nil)
                    sender.isOn = !sender.isOn
                } else {
                    if ConnectionCheck.isConnectedToNetwork() {
                        ReminderService.shared.twoDayBool = sender.isOn
                        self.updateSubscriptions()
                        ref.child("users").child((self.currentUser?.uid)!).child("notificationSettings").updateChildValues(["TwoDayNotification": ReminderService.shared.twoDayBool])
                    } else {
                        sender.isOn = !sender.isOn
                        messageAlert(title: "No Internet Connection", message: "Internet connection is required to update team notifications.", from: nil)
                    }
                }
            }
        }
    }
    
    
    @IBAction func oneDaySwitch(_ sender: UISwitch) {
        if currentUserSettings?.firstTimeTogglingNotificationSettings == true {
            messageAlert(title: "Notifications Setting Updated", message: "You have updated one of your settings. \n If the toggle is blue the setting is on, if the toggle is white the setting is off.", from: nil)
            currentUserSettings?.setValue(false, forKey: "firstTimeTogglingNotificationSettings")
            CoreDataService.shared.saveContext()
        }
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationAuthorizationStatus = settings.authorizationStatus
            
            DispatchQueue.main.async {
                
                if self.notificationAuthorizationStatus != .authorized {
                    messageAlert(title: "Notifications Permission Required", message: "In order to update notification settings, notification permission is required. \n\n Please go to your setting and turn on notifications for USSoccer.", from: nil)
                    sender.isOn = !sender.isOn
                    self.updateSubscriptions()
                } else {
                    if ConnectionCheck.isConnectedToNetwork() {
                        ReminderService.shared.oneDayBool = sender.isOn
                        ref.child("users").child((self.currentUser?.uid)!).child("notificationSettings").updateChildValues(["OneDayNotification": ReminderService.shared.oneDayBool])
                    } else {
                        sender.isOn = !sender.isOn
                        messageAlert(title: "No Internet Connection", message: "Internet connection is required to update team notifications.", from: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func twoHourSwitch(_ sender: UISwitch) {
        if currentUserSettings?.firstTimeTogglingNotificationSettings == true {
            messageAlert(title: "Notifications Setting Updated", message: "You have updated one of your settings. \n If the toggle is blue the setting is on, if the toggle is white the settings is off.", from: nil)
            currentUserSettings?.setValue(false, forKey: "firstTimeTogglingNotificationSettings")
            CoreDataService.shared.saveContext()
        }
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationAuthorizationStatus = settings.authorizationStatus
            
            DispatchQueue.main.async {
                
                if self.notificationAuthorizationStatus != .authorized {
                    messageAlert(title: "Notifications Permission Required", message: "In order to update notification settings, notification permission is required. \n\n Please go to your setting and turn on notifications for USSoccer.", from: nil)
                    sender.isOn = !sender.isOn
                } else {
                    if ConnectionCheck.isConnectedToNetwork() {
                        ReminderService.shared.twoHourBool = sender.isOn
                        self.updateSubscriptions()
                        ref.child("users").child((self.currentUser?.uid)!).child("notificationSettings").updateChildValues(["TwoHourNotification": ReminderService.shared.twoHourBool])
                    } else {
                        sender.isOn = !sender.isOn
                        messageAlert(title: "No Internet Connection", message: "Internet connection is required to update team notifications.", from: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func oneHourSwitch(_ sender: UISwitch) {
        if currentUserSettings?.firstTimeTogglingNotificationSettings == true {
            messageAlert(title: "Notifications Setting Updated", message: "You have updated one of your settings. \n If the toggle is blue the setting is on, if the toggle is white the setting is off.", from: nil)
            currentUserSettings?.setValue(false, forKey: "firstTimeTogglingNotificationSettings")
            CoreDataService.shared.saveContext()
        }
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationAuthorizationStatus = settings.authorizationStatus
            
            DispatchQueue.main.async {
                
                if self.notificationAuthorizationStatus != .authorized {
                    messageAlert(title: "Notifications Permission Required", message: "In order to update notification settings, notification permission is required. \n\n Please go to your setting and turn on notifications for USSoccer.", from: nil)
                    sender.isOn = !sender.isOn
                } else {
                    if ConnectionCheck.isConnectedToNetwork() {
                        ReminderService.shared.oneHourBool = sender.isOn
                        self.updateSubscriptions()
                        ref.child("users").child((self.currentUser?.uid)!).child("notificationSettings").updateChildValues(["OneHourNotification": ReminderService.shared.oneHourBool])
                    } else {
                        sender.isOn = !sender.isOn
                        messageAlert(title: "No Internet Connection", message: "Internet connection is required to update team notifications.", from: nil)
                    }
                }
            }
            
        }
    }
    
    @IBAction func halfHourSwitch(_ sender: UISwitch) {
        if currentUserSettings?.firstTimeTogglingNotificationSettings == true {
            messageAlert(title: "Notifications Setting Updated", message: "You have updated one of your settings. \n If the toggle is blue the setting is on, if the toggle is white the setting is off.", from: nil)
            currentUserSettings?.setValue(false, forKey: "firstTimeTogglingNotificationSettings")
            CoreDataService.shared.saveContext()
        }
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationAuthorizationStatus = settings.authorizationStatus
            
            DispatchQueue.main.async {
                
                if self.notificationAuthorizationStatus != .authorized {
                    messageAlert(title: "Notifications Permission Required", message: "In order to update notification settings, notification permission is required. \n\n Please go to your setting and turn on notifications for USSoccer.", from: nil)
                    sender.isOn = !sender.isOn
                } else {
                    if ConnectionCheck.isConnectedToNetwork() {
                        ReminderService.shared.halfHourBool = sender.isOn
                        self.updateSubscriptions()
                        ref.child("users").child((self.currentUser?.uid)!).child("notificationSettings").updateChildValues(["HalfHourNotification": ReminderService.shared.halfHourBool])
                    } else {
                        sender.isOn = !sender.isOn
                        messageAlert(title: "No Internet Connection", message: "Internet connection is required to update team notifications.", from: nil)
                    }
                }
            }
        }
    }
}
