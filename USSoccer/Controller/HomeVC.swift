//
//  HomeVC.swift
//  USSoccer
//
//  Created by Jared Sobol on 11/11/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import CoreData
import UserNotifications
import OneSignal
import UserNotifications

class HomeVC: UIViewController {
    
    @IBOutlet weak var notificationAlertLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var teamPicker: UIPickerView!
    @IBOutlet weak var NMTableView: UITableView!
    @IBOutlet weak var twoDaySwitch: UISwitch!
    @IBOutlet weak var oneDaySwitch: UISwitch!
    @IBOutlet weak var twoHourSwitch: UISwitch!
    @IBOutlet weak var oneHourSwitch: UISwitch!
    @IBOutlet weak var halfHourSwitch: UISwitch!
    @IBOutlet weak var infoBtn: UIBarButtonItem!
    
    @IBOutlet var menuShaddowView: UIView!
    @IBOutlet weak var notificationMenuTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var notificationAlertTopConstraint: NSLayoutConstraint!
    var pickerTeamsArray = ["U-15 MNT", "U-16 MNT", "U-17 MNT", "U-18 MNT", "U-19 MNT", "U-20 MNT", "U-23 MNT", "MNT", "ALL TEAMS", "WNT", "U-23 WNT", "U-20 WNT", "U-19 WNT", "U-18 WNT", "U-17 WNT", "U-16 WNT", "U-15 WNT"]
    var rotationAngle: CGFloat!
    let notificationVC = NotificationMenuView()
    var customHeight: CGFloat = 0.0
    var customWidth: CGFloat = 0.0
    let formatter = DateFormatter()
    var filterValue: String!
    var sortedGames = [String: [SoccerGame]]()
    var soccerGames = [SoccerGame]()
    var currentUserSettings : Person? {
        return CoreDataService.shared.fetchPerson()
    }
    var notificationAuthorizationStatus : UNAuthorizationStatus = .notDetermined
  
    var notificationAlertVisible = false
    var notificationMenuVisible = false
    var notificationAlertHideTimer : Timer?
    var currentUser = Auth.auth().currentUser

    
    @IBOutlet var notificationMenuView: NotificationMenuView!
    @IBOutlet var notificationView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rotationAngle = -150 * (.pi/100)
        teamPicker.delegate = self
        teamPicker.dataSource = self
        
        NMTableView.delegate = notificationVC
        NMTableView.dataSource = notificationVC
        tableView.delegate = self
        tableView.dataSource = self
        let superView = teamPicker.superview!
        tableView.separatorStyle = .none
        teamPicker.transform = CGAffineTransform(rotationAngle: rotationAngle)
        customWidth = superView.bounds.height
        customHeight = superView.bounds.height
//        switch UIScreen.main.nativeBounds.height {
//        /*case 1136:
//            print("iPhone 5 or 5S or 5C")
//        case 1334:
//            print("iPhone 6/6S/7/8")
//        case 2208:
//            print("iPhone 6+/6S+/7+/8+")*/
//        case 2436:
//            print("iPhone X")
//            teamPicker.frame = CGRect(x: -100, y: view.frame.height - 103, width: view.frame.width + 200, height: 68)
//        default:
//            teamPicker.frame = CGRect(x: -100, y: view.frame.height - 73, width: view.frame.width + 200, height: 68)
//        }
        teamPicker.translatesAutoresizingMaskIntoConstraints = false
        teamPicker.widthAnchor.constraint(equalToConstant: superView.bounds.height).isActive = true
        teamPicker.heightAnchor.constraint(equalToConstant: superView.superview!.bounds.width + 300).isActive = true
        teamPicker.centerXAnchor.constraint(equalTo: superView.centerXAnchor).isActive = true
        teamPicker.centerYAnchor.constraint(equalTo: superView.centerYAnchor).isActive = true
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFont(name: "HelveticaNeue-CondensedBold", size: 28.0)!,NSAttributedStringKey.foregroundColor: UIColor.white]
        
        twoDaySwitch.onTintColor = blueColor
        oneDaySwitch.onTintColor = blueColor
        twoHourSwitch.onTintColor = blueColor
        oneHourSwitch.onTintColor = blueColor
        halfHourSwitch.onTintColor = blueColor
        
        NotificationCenter.default.addObserver(self,
                                                 selector: #selector(HomeVC.appWillBecomeActive(_:)),
                                                 name: NSNotification.Name.UIApplicationDidBecomeActive,
                                                 object: nil)
        
        if currentUserSettings?.firstTimeInApp == true {
            let introAlert = UIAlertController(title: "Welcome To US Soccer" , message: "US Soccer shows you a list of all USA National Soccer Teams games. \n\n Swipe left or right on the bottom to sort the list by the team. \n Click on a \"bell\" icon to set a notification for that game. \n\n Please give US Soccer permission to send notifications for the soccer games you select.", preferredStyle: UIAlertControllerStyle.alert)
            
            introAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (error) in
                self.currentUserSettings?.setValue(false, forKey: "firstTimeInApp")
                CoreDataService.shared.saveContext()
                
                // Ask for the push notification permission
                OneSignal.promptPushNotificationAlert()
                self.isWaitingForDismissPermissionsDialog = true
                
            }))
             self.present(introAlert, animated: true, completion: nil)

            
        }
        
        
        setupTeamPicker()
    }
    
    
    func refreshSettings() {
        
        ref.child("users").child(currentUser!.uid).observeSingleEvent(of: .value) { (snapshot) in
            DispatchQueue.main.async {
                
                let value = snapshot.value as? NSDictionary
                let notifications = value?["notificationSettings"] as? NSDictionary
                
                ReminderService.shared.halfHourBool = notifications?["HalfHourNotification"] as? Bool ?? false
                ReminderService.shared.oneDayBool = notifications?["OneDayNotification"] as? Bool ?? false
                ReminderService.shared.oneHourBool = notifications?["OneHourNotification"] as? Bool ?? false
                ReminderService.shared.twoDayBool = notifications?["TwoDayNotification"] as? Bool ?? false
                ReminderService.shared.twoHourBool = notifications?["TwoHourNotification"] as? Bool ?? true
                
                self.halfHourSwitch.setOn(ReminderService.shared.halfHourBool, animated: false)
                self.oneDaySwitch.setOn(ReminderService.shared.oneDayBool, animated: false)
                self.oneHourSwitch.setOn(ReminderService.shared.oneHourBool, animated: false)
                self.twoDaySwitch.setOn(ReminderService.shared.twoDayBool, animated: false)
                self.twoHourSwitch.setOn(ReminderService.shared.twoHourBool, animated: false)
            }
        }
    }
    
    
    func setupTeamPicker() {
        //Checking to see if the Teams are set up in CoreData, Setting them up if they are not
        let teams = CoreDataService.shared.fetchTeams()
        
        let existingTeamTitles = teams.flatMap { (team: Team) -> String? in
            return team.title
        }
        for teamTitle in pickerTeamsArray {
            
            if existingTeamTitles.contains(teamTitle) == false {
                CoreDataService.shared.saveTeam(title: teamTitle)
            }
        }
        
        
        
        ApiCaller.shared.updateLocalTeamsNotificationSettings(completion: { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        })
        
        
        if sortedGames["MNT"] == nil{
            sortedGames["MNT"] = [SoccerGame]()
        }
        if sortedGames["WNT"] == nil{
            sortedGames["WNT"] = [SoccerGame]()
        }
        
        
        
        if !ConnectionCheck.isConnectedToNetwork() {
            messageAlert(title: "Offline Mode", message: "Games Information may not be accurate due to no internet connection. \n Please connect to the internet and restart USA Soccer for the full experience", from: nil)
        } else {
            refreshSettings()
        }// End else statement
        
        
        
        if (sortedGames["MNT"]!.isEmpty){
            let newGame = SoccerGame(title: "No Upcoming Games", date: "NA", time: "NA", venue: "NA", stations: "NA")
            sortedGames["MNT"]!.append(newGame)
        }
        
        if (sortedGames["WNT"]!.isEmpty) {
            let newGame = SoccerGame(title: "No Upcoming Games", date: "NA", time: "NA", venue: "NA", stations: "NA")
            sortedGames["WNT"]!.append(newGame)
        }
        
        if (sortedGames["ALL TEAMS"]!.isEmpty) {
            let newGame = SoccerGame(title: "Internet Access Required!", date: "NA", time: "NA", venue: "NA", stations: "NA")
            sortedGames["ALL TEAMS"]!.append(newGame)
        }
        
        
        
        if let index = pickerTeamsArray.index(of: "ALL TEAMS") {
            teamPicker?.selectRow(index, inComponent: 0, animated: true)
        }
        
        
        
        filterValue = "ALL TEAMS"
        soccerGames = sortedGames[filterValue] ?? [SoccerGame]()
        tableView.reloadData()
    }
    
    private var isWaitingForDismissPermissionsDialog = false
    private var isWaitingForDismissInfoTutorial = false
    
    @objc func appWillBecomeActive(_ notification: Notification) {
        
        
        // Check if the
        if isWaitingForDismissPermissionsDialog == true {
            isWaitingForDismissPermissionsDialog = false
            // Present the rest of the first time in app stuff
            
            if self.currentUserSettings?.firstTimeClickingInfo == true {
                sleep(UInt32(0.5))
                self.performSegue(withIdentifier: "infoSegue", sender: nil)
                let _ = UIAlertController.presentOKAlertWithTitle("App Info", message: "This list contains all of the abbreviantions & symbols used in the app. \n\n Click the \"i\" icon to open this menu.", okTapped: {
                    self.isWaitingForDismissInfoTutorial = true
                    
                    self.currentUserSettings?.setValue(false, forKey: "firstTimeClickingInfo")
                    CoreDataService.shared.saveContext()
                })
            }
            
            
        }
    }
    
    func presentNotificationTutorial() {
        
        
        // Check if the
        if isWaitingForDismissInfoTutorial == true {
            isWaitingForDismissInfoTutorial = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        
        
        if let view = navigationController?.view {
            view.addSubview(menuShaddowView)
            if 1 == 1 { // 1==1 create a new scope for free basically
                let trailingConstraint = NSLayoutConstraint(item: menuShaddowView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0.0)
                let topConstraint = NSLayoutConstraint(item: menuShaddowView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0.0)
                let bottomConstraint = NSLayoutConstraint(item: menuShaddowView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0.0)
                let leadingConstraint = NSLayoutConstraint(item: menuShaddowView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0.0)
                view.addConstraint(trailingConstraint)
                view.addConstraint(topConstraint)
                view.addConstraint(bottomConstraint)
                view.addConstraint(leadingConstraint)
                
                menuShaddowView.isHidden = true
            }
            
            view.addSubview(notificationMenuView)
            
            let trailingConstraint = NSLayoutConstraint(item: notificationMenuView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0.0)
            var topConstraint : NSLayoutConstraint!
            
            if #available(iOS 11.0, *) {
                topConstraint = NSLayoutConstraint(item: notificationMenuView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1.0, constant: -64.0)
            } else {
                topConstraint = NSLayoutConstraint(item: notificationMenuView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: .top, multiplier: 1.0, constant: -64.0)
            }
            
            let bottomConstraint = NSLayoutConstraint(item: notificationMenuView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0.0)
            view.addConstraint(trailingConstraint)
            view.addConstraint(topConstraint)
            view.addConstraint(bottomConstraint)
            
            notificationMenuTrailingConstraint = trailingConstraint
            notificationMenuTrailingConstraint.constant = 187
            
            
            
            view.addSubview(notificationView)
            
            let trailingConstraint2 = NSLayoutConstraint(item: notificationView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0.0)
            let topConstraint2 = NSLayoutConstraint(item: notificationView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0.0)
            let leadingConstraint2 = NSLayoutConstraint(item: notificationView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0.0)
            view.addConstraint(trailingConstraint2)
            view.addConstraint(topConstraint2)
            view.addConstraint(leadingConstraint2)
            
            notificationAlertTopConstraint = topConstraint2
            notificationAlertTopConstraint.constant = -notificationView.frame.size.height
            
            
            navigationController?.view.layoutIfNeeded()
        }
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        notificationMenuView.removeFromSuperview()
        notificationView.removeFromSuperview()
        menuShaddowView.removeFromSuperview()
    }
    
    @IBAction func settingBtnPressed(_ sender: Any) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationAuthorizationStatus = settings.authorizationStatus
            
            DispatchQueue.main.async {
                
                if self.notificationAuthorizationStatus != .authorized {
                    messageAlert(title: "Notifications Permission Required", message: "In order to update notification settings, notification permission is required. \n\n Please go to your setting and turn on notifications for USSoccer.", from: nil)
                } else {
                    if !ConnectionCheck.isConnectedToNetwork() {
                        messageAlert(title: "No Internet Connection!", message: "Notifications Setting Menu is not available in Offline Mode.", from: nil)
                    } else {
                        self.openMenu()
                        if self.currentUserSettings?.firstTimeClickingSetting == true {
                            messageAlert(title: "Notifications Settings Menu", message: "Set up when you want to recieve notifications, The default is two hours before a game \n\n Click on one of the teams in the list to recieve notifications for all their games.", from: nil)
                            self.currentUserSettings?.setValue(false, forKey: "firstTimeClickingSetting")
                            CoreDataService.shared.saveContext()
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        closeMenu()
    }
    
    
    
    
    @IBAction func notificationMenuSwipedOff(_ sender: Any) {
        closeMenu()
    }
    // MARK: - Menu manipulation
    
    func openMenu() {
        menuShaddowView.isHidden = false
        menuShaddowView.alpha = 0.0
        notificationMenuTrailingConstraint?.constant = 0.0
        notificationAlertTopConstraint?.constant = -notificationView.frame.size.height
        UIView.animate(withDuration: 0.3, animations: {
            self.menuShaddowView.alpha = 1.0
            self.navigationController?.view.layoutIfNeeded()
        }, completion: { (finished: Bool) in
            self.notificationMenuVisible = true
            self.notificationAlertVisible = false
        })
    }
    
    func closeMenu() {
        notificationMenuTrailingConstraint.constant = 187
        UIView.animate(withDuration: 0.3, animations: {
            self.navigationController?.view.layoutIfNeeded()
            self.menuShaddowView.alpha = 0.0
        }) { (finished: Bool) in
            self.notificationMenuVisible = false
            self.menuShaddowView.isHidden = true
        }
        
        tableView.reloadData()
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "gameDetail" {
                let soccerGame = sender as! SoccerGame
                let detailViewController = segue.destination as! GameDetailVC
                detailViewController.soccerGame = soccerGame
            }
            if let vc = segue.destination as? InfoVC {
                vc.presentingVC = self
            }
    }
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let game = soccerGames[indexPath.row]
        if game.isPlaceholder() == false {
            NavigationService.shared.navigate(toGame: game)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return soccerGames.count
    }
    
    
    /*
     separeted the arrays by team
     sorted the individual arrays
     put the all together again to form a all teams array
     */
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GamesTVCell", for: indexPath) as? GamesTVCell else {
            fatalError("The Cell Failed to Deque")
        }
        cell.notificationBtn.addTarget(self, action: #selector(notificationButtonClicked(sender:)), for: .touchUpInside)
        
        // Checking for PlaceHolderGame and adjusting displayed text accordingly
        let game = soccerGames[indexPath.row]
        let gameTime = game.time
        
        if game.isInThePast() {
            
            cell.gameDateLbl.alpha = 0.5
            cell.gameTitleLbl.alpha = 0.5
            cell.vsLbl.alpha = 0.5
            cell.opponentLbl.alpha = 0.5
            cell.gameTimeLbl.alpha = 0.5
            cell.notificationBtn.isHidden = true
        } else {
            cell.gameDateLbl.alpha = 1.0
            cell.gameTitleLbl.alpha = 1.0
            cell.vsLbl.alpha = 1.0
            cell.opponentLbl.alpha = 1.0
            cell.gameTimeLbl.alpha = 1.0
            cell.notificationBtn.isHidden = false
        }
        
        if gameTime == "NA" {
            cell.gameDateLbl.text = soccerGames[indexPath.row].title
            cell.gameTitleLbl.text = ""
            cell.vsLbl.text = ""
            cell.opponentLbl.text = ""
        } else {
            let usSoccerTitle = soccerGames[indexPath.row].title?.components(separatedBy: " ") ?? [String]()
            if usSoccerTitle.count > 2 {
                if usSoccerTitle[1].lowercased() != "vs" {
                    cell.gameTitleLbl.text = "\(usSoccerTitle[0].uppercased()) \(usSoccerTitle[1].uppercased())"
                    cell.vsLbl.text = "\(usSoccerTitle[2].uppercased())"
                    cell.opponentLbl.text = "\(usSoccerTitle[3].uppercased())"
                } else {
                    cell.gameTitleLbl.text = "\(usSoccerTitle[0].uppercased())"
                    cell.vsLbl.text = "\(usSoccerTitle[1].uppercased())"
                    cell.opponentLbl.text = "\(usSoccerTitle[2].uppercased())"
                }
            } else {
            }
            
            let currentGame = soccerGames[indexPath.row]
            
            if isGameSelectedForNotifications(game: currentGame) {
                // Notifications ON
                cell.notificationBtn.setImage(UIImage(named: "bell-musical-tool (1)"), for: .normal)
            } else {
                if currentGame.notification == nil {
                    // Undefined
                    cell.notificationBtn.setImage(UIImage(named: "musical-bell-outline (2)"), for: .normal)
                } else {
                    // Notifications OFF
                    // currentGame.notification == false
                    cell.notificationBtn.setImage(UIImage(named: "musical-bell-outline (2)"), for: .normal)
                }
            }
            
            // canclednotifications
        }
        let gameDate = soccerGames[indexPath.row].date?.components(separatedBy: " ") ?? ["NA"]
        //Checking for PlaceholderGame
        if gameDate[0] == "NA" {
            cell.gameTimeLbl.text = ""
            cell.notificationBtn.isHidden = true
        } else {
            let formatedMonth = gameDate[0].prefix(3)
            cell.gameDateLbl.text = "\(formatedMonth.uppercased()) \(gameDate[1]) \(gameDate[2])"
            if let date = soccerGames[indexPath.row].timestamp {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .none
                dateFormatter.timeStyle = .short
                let strDate = dateFormatter.string(from: date)
                cell.gameTimeLbl.text = strDate
            }
        }
        
        return cell
    }
    
    func isGameSelectedForNotifications(game: SoccerGame) -> Bool {
        var isSelected = false
        if let isGameSelected = game.notification?.boolValue {
            isSelected = isGameSelected
        } else {
            var teamIsSelected = false
            if let team = team(forGame: game) {
                teamIsSelected = team.notifications
            }
            var allTeamsAreSelected = false
            if let team = CoreDataService.shared.team(name: "ALL TEAMS") {
                allTeamsAreSelected = team.notifications
            }
            
            isSelected = teamIsSelected || allTeamsAreSelected
        }
        return isSelected
    }
    
    func team(forGame game: SoccerGame) -> Team? {
        return CoreDataService.shared.team(name: game.usTeam)
    }
    
    
    @IBAction func notificationsSettingsTapped(_ sender: Any) {
        openMenu()
    }
    
    @objc func notificationAlertHideTimerFired() {
        // Hide after some time
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            if let height = self?.notificationView?.frame.size.height {
                self?.notificationAlertTopConstraint?.constant = -height
            }
            self?.navigationController?.view.layoutIfNeeded()
        }, completion: { [weak self] (finished: Bool) in
            self?.notificationAlertVisible = false
        })
    }
    
    
    @objc func notificationButtonClicked(sender: UIButton) {
        if ConnectionCheck.isConnectedToNetwork() {
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                self.notificationAuthorizationStatus = settings.authorizationStatus
                DispatchQueue.main.async {
                    self.handleNotifications(sender: sender)
                }
            }
        } else {
            messageAlert(title: "No Internet Connection!", message: "Internet connection is required to update game notifications.", from: nil)
        }
    }
    
    private func handleNotifications(sender: UIButton) {
        
        // Get the game
        let buttonPosition = sender.convert(CGPoint.zero, to: tableView)
        let indexPath: IndexPath! = tableView.indexPathForRow(at: buttonPosition)
        let game = soccerGames[indexPath.row]
        
        // Get the notification toggle
        let isSelected = self.isGameSelectedForNotifications(game: game)
            if notificationAuthorizationStatus != .authorized {
                messageAlert(title: "Notifications Permission Required", message: "In order to send a notificaiton, notification permission is required. \n\n Please go to your setting and turn on notifications for USSoccer.", from: nil)
            } else {
                
                if ConnectionCheck.isConnectedToNetwork() {
                    
                    if currentUserSettings?.firstTimeClickingBell == true && isSelected == false {
                        messageAlert(title: "Notification Set", message: "A notification has been set for this game. \n\nTo update your notificaiton settings press the \"Gear\" icon in the top right corner", from: nil)
                        currentUserSettings?.setValue(false, forKey: "firstTimeClickingBell")
                        CoreDataService.shared.saveContext()
                    }
                    
                    // Set the notification toggle
                    let isSelected = !self.isGameSelectedForNotifications(game: game)
                    
                    game.notification = NSNumber(value: isSelected)
                    CoreDataService.shared.saveContext()
                    
                    if let team = team(forGame: game), let uid = Auth.auth().currentUser?.uid {
                        
                        // Configure the notification alert tab
                        notificationAlertLbl.text = "\(team.title?.uppercased() ?? "Name not available") Notification Set"
                    
                        if isSelected {
                            
                            // Schedule a local notification, but only if this user doesn't observe the team changes
                            // We want to prevent double notifications
                            let ref : DatabaseReference = followingRef.child(team.title!).child(uid)
                            ref.observeSingleEvent(of: .value, with: { (snapshot : DataSnapshot) in
                                let isFollowing = snapshot.value as? Bool ?? false
                                if isFollowing == false {
                                    ReminderService.shared.scheduleAllLocalNotifications(forGame: game)
                                }
                            })
                        } else {
                            // Cancel notifications
                            ReminderService.shared.cancelAllSchduledLocalNotifications(ofGame: game)
                        }
                    }
                    
                    
                    if isSelected {
                        // Showing the notification tab - we're telling the user that it's been scheduled
                        notificationAlertVisible = !notificationAlertVisible
                        if notificationAlertVisible {
                            // Showing
                            notificationAlertTopConstraint.constant = 0.0
                            UIView.animate(withDuration: 0.3, animations: {
                                self.navigationController?.view.layoutIfNeeded()
                            }, completion: { (finished: Bool) in
                                
                                self.notificationAlertHideTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(HomeVC.notificationAlertHideTimerFired), userInfo: nil, repeats: false)
                            })
                            
                        } else {
                            // Hiding
                            notificationAlertTopConstraint.constant = -notificationView.frame.size.height
                            UIView.animate(withDuration: 0.3) {
                                self.navigationController?.view.layoutIfNeeded()
                            }
                        }
                    }
                    
                    tableView.reloadRows(at: [indexPath], with: .none)
                } else {
                    messageAlert(title: "No Internet Connection!", message: "Internet connection is required to update game notifications.", from: nil)
                }
            }
        }
}

extension HomeVC: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerTeamsArray.count
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return customHeight + 18
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return customWidth
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        tableView.setContentOffset(CGPoint.zero, animated: false)
        filterValue = pickerTeamsArray[row]
        soccerGames = sortedGames[filterValue] ?? [SoccerGame]()
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.reloadData()
        
        if tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0 {
            tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let nameLabel = UILabel()
        nameLabel.frame = CGRect(x: 0, y: 0, width: customWidth + 10, height: customHeight)
//        let view = UIView(frame: CGRect(x: 0, y: 0, width: customWidth, height: customHeight))
//        let nameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: customWidth, height: customHeight))
        nameLabel.text = pickerTeamsArray[row]
        nameLabel.textAlignment = .center
        nameLabel.transform = CGAffineTransform(rotationAngle: 150 * (.pi/100))
        nameLabel.textColor = UIColor.white
        nameLabel.font = UIFont(name: "HelveticaNeue-CondensedBold", size: 19.0)
        
//        view.addSubview(nameLabel)
//        view.transform = CGAffineTransform(rotationAngle: (150 * (.pi/100)))
        return nameLabel
    }
}

