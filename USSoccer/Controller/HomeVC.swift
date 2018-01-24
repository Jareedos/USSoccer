//
//  HomeVC.swift
//  USSoccer
//
//  Created by Jared Sobol on 11/11/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import CoreData
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
    
    @IBOutlet var menuShaddowView: UIView!
    @IBOutlet weak var notificationMenuTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var notificationAlertTopConstraint: NSLayoutConstraint!
    var pickerTeamsArray = ["U-15 MNT", "U-16 MNT", "U-17 MNT", "U-18 MNT", "U-19 MNT", "U-20 MNT", "U-23 MNT", "MNT", "ALL TEAMS", "WNT", "U-23 WNT", "U-20 WNT", "U-19 WNT", "U-18 WNT", "U-17 WNT", "U-16 WNT", "U-15 WNT"]
    var rotationAngle: CGFloat!
    let notificationVC = NotificationMenuView()
    let customHeight: CGFloat = 100
    let customWidth: CGFloat = 100
    var twoDayBool = false
    var oneDayBool = false
    var twoHourBool = false
    var oneHourBool = false
    var halfHourBool = false
    let formatter = DateFormatter()
    var filterValue: String!
    var sortedGames = [String: [SoccerGame]]()
    var soccerGames = [SoccerGame]()
    var teamArray = [Team]()
    var currentUserSettings : Person? {
        return CoreDataService.shared.fetchPerson()
    }
    //let notificationType = UIApplication.shared.currentUserNotificationSettings!.types
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
        tableView.separatorStyle = .none
        teamPicker.transform = CGAffineTransform(rotationAngle: rotationAngle)
        
        switch UIScreen.main.nativeBounds.height {
        /*case 1136:
            print("iPhone 5 or 5S or 5C")
        case 1334:
            print("iPhone 6/6S/7/8")
        case 2208:
            print("iPhone 6+/6S+/7+/8+")*/
        case 2436:
            print("iPhone X")
            teamPicker.frame = CGRect(x: -100, y: view.frame.height - 103, width: view.frame.width + 200, height: 68)
        default:
            teamPicker.frame = CGRect(x: -100, y: view.frame.height - 73, width: view.frame.width + 200, height: 68)
        }
        
        
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
        let dict: [String: Bool] = ["TwoDayNotification": twoDayBool, "OneDayNotification": oneDayBool, "TwoHourNotification": twoHourBool, "OneHourNotification": oneHourBool, "HalfHourNotification": halfHourBool]
        notificationsRef.setValue(dict)
        
        if currentUserSettings?.firstTimeInApp == true {
            messageAlert(title: "Welcome To US Soccer", message: "US Soccer shows you a list of all USA National Soccer Teams games. \n Swipe left or right on the bottom to sort the list by the team. \n Click on a bell to set a notification for that game. \n\n Please give US Soccer permission to send notifications for the soccer games you select.", from: nil)
            currentUserSettings?.setValue(false, forKey: "firstTimeInApp")
            CoreDataService.shared.saveContext()
        }
        
        if !ConnectionCheck.isConnectedToNetwork() {
            messageAlert(title: "Offline Mode", message: "Games Information may not be accurate due to no internet connection. \n Please connect to the internet and restart USA Soccer for the full experience", from: nil)
        } else {
            ref.child("users").child("\(String(describing: currentUser))").observeSingleEvent(of: .value) { (snapshot) in
                
                guard let value = snapshot.value as? NSDictionary, let notifications = value["notificationSettings"] as? NSDictionary else { return }
                
                let halfHourNotification = notifications["HalfHourNotification"] as? Bool ?? false
                let oneDayNotification = notifications["OneDayNotification"] as? Bool ?? false
                let oneHourNotification = notifications["OneHourNotification"] as? Bool ?? false
                let twoDayNotification = notifications["TwoDayNotification"] as? Bool ?? false
                let twoHourNotification = notifications["TwoHourNotification"] as? Bool ?? true
                
                self.halfHourSwitch.setOn(halfHourNotification, animated: false)
                self.oneDaySwitch.setOn(oneDayNotification, animated: false)
                self.oneHourSwitch.setOn(oneHourNotification, animated: false)
                self.twoDaySwitch.setOn(twoDayNotification, animated: false)
                self.twoHourSwitch.setOn(twoHourNotification, animated: false)
            }
            
            let currentDate = Date()
            formatter.dateFormat = "MMMM dd, yyyy h:mm a ZZZ"
            let currentDateResult = formatter.string(from: currentDate)
            let dateFormated = formatter.date(from: currentDateResult)?.timeIntervalSince1970
            
            for (key,value) in sortedGames {
                for game in value {
                    print("\(game.timestamp?.description ?? "nothing - no date")")
                }
                
                sortedGames[key] = value.sorted(by: {
                    $0.timestamp?.timeIntervalSince1970 ?? 0.0 < $1.timestamp?.timeIntervalSince1970 ?? 0.0})
                for (index, game) in value.enumerated() {
                    //                    if game.timestamp == nil {
                    //                        game.timestamp = Date(timeIntervalSince1970: 1511193000.0)
                    //                    }
                    if game.timestamp!.timeIntervalSince1970 < dateFormated! {
                        sortedGames[key]!.remove(at: index)
                        gamesRef.child("\(game.title!)\(game.date!)").removeValue()
                        CoreDataService.shared.delete(object: game)
                    }
                }
            }
            
        }
        
        //Checking to see if the Teams are set up in CoreData, Setting them up if they are not
        teamArray = CoreDataService.shared.fetchTeams()
        if teamArray.isEmpty {
            for teamTitle in pickerTeamsArray {
                CoreDataService.shared.saveTeam(title: teamTitle)
            }
        }
        
        // Creating a set for all the Teams Titles that have games schedualed
        var existingKeys : Set<String> = ["MNT", "ALL TEAMS", "WNT"]
        var allGames = [SoccerGame]()
        for key in sortedGames.keys {
            existingKeys.insert(key)
            allGames += sortedGames[key]!
        }
        
        allGames = allGames.sorted(by: {
            $0.timestamp?.timeIntervalSince1970 ?? 0.0 < $1.timestamp?.timeIntervalSince1970 ?? 0.0})
        
        sortedGames["ALL TEAMS"] = allGames
        
        // Remove the missing ones
        var updatedPickerTeamsArray = [String]()
        for team in pickerTeamsArray {
            if existingKeys.contains(team) {
                updatedPickerTeamsArray.append(team)
            }
        }
        pickerTeamsArray = updatedPickerTeamsArray
        
        if let index = pickerTeamsArray.index(of: "ALL TEAMS") {
            teamPicker.selectRow(index, inComponent: 0, animated: true)
        }
        
        filterValue = "ALL TEAMS"
        soccerGames = sortedGames[filterValue] ?? [SoccerGame]()
        if sortedGames["MNT"] == nil{
            sortedGames["MNT"] = [SoccerGame]()
        }
        if sortedGames["WNT"] == nil{
            sortedGames["WNT"] = [SoccerGame]()
        }
        guard let mensNational = sortedGames["MNT"] else {
            print("Men's national wasn't found")
            fatalError()
        }
        if (mensNational.isEmpty){
            let newGame = SoccerGame(title: "No Upcoming Games Available", date: "NA", time: "NA", venue: "NA", stations: "NA")
            sortedGames["MNT"]!.append(newGame)
        }

        if (sortedGames["WNT"]!.isEmpty) {
            let newGame = SoccerGame(title: "No Upcoming Games Available", date: "NA", time: "NA", venue: "NA", stations: "NA")
            sortedGames["WNT"]!.append(newGame)
        }
        
        if (sortedGames["ALL TEAMS"]!.isEmpty) {
            let newGame = SoccerGame(title: "Internet Access Required For Game Info", date: "NA", time: "NA", venue: "NA", stations: "NA")
            sortedGames["ALL TEAMS"]!.append(newGame)
        }
        tableView.reloadData()
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
            let topConstraint = NSLayoutConstraint(item: notificationMenuView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1.0, constant: -64.0)
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
                    print("notifications are NOT enabled")
                } else {
                    if !ConnectionCheck.isConnectedToNetwork() {
                        messageAlert(title: "No Internet Connection", message: "Notifications Setting Menu is not available in Offline Mode.", from: nil)
                    } else {
                        self.openMenu()
                        if self.currentUserSettings?.firstTimeClickingSetting == true {
                            messageAlert(title: "Notifications Menu", message: "Set up when you want to recieve notifications, The default is two hours before a game \n Click on one of the Teams to recieve notifications for all their games.", from: nil)
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
        notificationMenuTrailingConstraint.constant = 0.0
        notificationAlertTopConstraint.constant = -notificationView.frame.size.height
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
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gameDetail" {
            let gameCellThatWasClicked = sender as! UITableViewCell
            let indexPath = self.tableView.indexPath(for: gameCellThatWasClicked)
            let soccerGame = soccerGames[(indexPath?.row)!]
            let detailViewController = segue.destination as! GameDetailVC
            detailViewController.soccerGame = soccerGame
        }
    }
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    
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
        let gameTime = soccerGames[indexPath.row].time
        
        if gameTime == "NA" {
            cell.gameDateLbl.text = soccerGames[indexPath.row].title
            cell.gameTitleLbl.text = ""
            cell.vsLbl.text = ""
            cell.opponentLbl.text = ""
        } else {
            let usSoccerTitle = soccerGames[indexPath.row].title?.components(separatedBy: " ") ?? [String]()
            if usSoccerTitle.count > 1 {
                if usSoccerTitle[1] != "vs" {
                    cell.gameTitleLbl.text = "\(usSoccerTitle[0].uppercased()) \(usSoccerTitle[1].uppercased())"
                    cell.vsLbl.text = "\(usSoccerTitle[2].uppercased())"
                    cell.opponentLbl.text = "\(usSoccerTitle[3].uppercased())"
                } else {
                    cell.gameTitleLbl.text = "\(usSoccerTitle[0].uppercased())"
                    cell.vsLbl.text = "\(usSoccerTitle[1].uppercased())"
                    cell.opponentLbl.text = "\(usSoccerTitle[2].uppercased())"
                }
            }
            
            let currentGame = soccerGames[indexPath.row] 
                if currentGame.notification == true {
                    cell.notificationBtn.setImage(UIImage(named: "bell-musical-tool (1)"), for: .normal)
                } else {
                    cell.notificationBtn.setImage(UIImage(named: "musical-bell-outline (2)"), for: .normal)
                }
        }
        let gameDate = soccerGames[indexPath.row].date!.components(separatedBy: " ")
        //Checking for PlaceholderGame
        if gameDate[0] == "NA" {
            cell.gameTimeLbl.text = ""
            cell.notificationBtn.isHidden = true
        } else {
            let formatedMonth = gameDate[0].prefix(3)
            cell.gameDateLbl.text = "\(formatedMonth.uppercased()) \(gameDate[1]) \(gameDate[2])"
            let date = soccerGames[indexPath.row].timestamp
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            let strDate = dateFormatter.string(from: date!)
            cell.gameTimeLbl.text = strDate
            cell.notificationBtn.isHidden = false
        }
        
        return cell
    }
    
    func team(forGame game: SoccerGame) -> Team? {
        // Get the team from
        let teams = teamArray.filter { (team: Team) -> Bool in
            return team.title == game.usTeam
        }
        return teams.first
    }
    
    
    @IBAction func notificationsSettingsTapped(_ sender: Any) {
        openMenu()
    }
    
    @objc func notificationAlertHideTimerFired() {
        // Hide after some time
        UIView.animate(withDuration: 0.3, animations: {
            self.notificationAlertTopConstraint.constant = -self.notificationView.frame.size.height
            self.navigationController?.view.layoutIfNeeded()
        }, completion: { (finished: Bool) in
            self.notificationAlertVisible = false
        })
    }
    
    
    @objc func notificationButtonClicked(sender: UIButton) {
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationAuthorizationStatus = settings.authorizationStatus
            
            DispatchQueue.main.async {
                self.handleNotifications(sender: sender)
            }
        }
    }
    
    private func handleNotifications(sender: UIButton) {
        if currentUserSettings?.firstTimeClickingBell == true {
            messageAlert(title: "Notification Set", message: "A notification has been set for this game. To update your notificaiton settings press the \"Gear\" icon in the top right corner", from: nil)
            currentUserSettings?.setValue(false, forKey: "firstTimeClickingBell")
            CoreDataService.shared.saveContext()
        }
            if notificationAuthorizationStatus != .authorized {
                messageAlert(title: "Notifications Permission Required", message: "In order to send a notificaiton, notification permission is required. \n\n Please go to your setting and turn on notifications for USSoccer.", from: nil)
                print("notifications are NOT enabled")
            } else {
                if ConnectionCheck.isConnectedToNetwork() {
                    let buttonPosition = sender.convert(CGPoint.zero, to: tableView)
                    let indexPath: IndexPath! = tableView.indexPathForRow(at: buttonPosition)
                    let game = soccerGames[indexPath.row]
                    game.notification = NSNumber(value: !(game.notification?.boolValue ?? false))
                    CoreDataService.shared.saveContext()
                    if let team = team(forGame: game) {
                        notificationAlertLbl.text = "\(team.title?.uppercased() ?? "Name not available") Notification Set"
                    }
                    
                    if game.notification!.boolValue {
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
                    tableView.reloadData()
                    print("I got here")
                } else {
                    messageAlert(title: "No Internet Connection", message: "Internet connection is required to update game notifications.", from: nil)
                }
                print("notifications are enabled")
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
        return customHeight
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        self.tableView.contentOffset = CGPoint.zero
        
        self.filterValue = self.pickerTeamsArray[row]
        self.soccerGames = self.sortedGames[self.filterValue] ?? [SoccerGame]()
        
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.view.layoutIfNeeded()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: customWidth, height: customHeight))
        let nameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: customWidth, height: customHeight))
        nameLabel.text = pickerTeamsArray[row]
        nameLabel.textAlignment = .center
        nameLabel.textColor = UIColor.white
        nameLabel.font = UIFont(name: "HelveticaNeue-CondensedBold", size: 19.0)
        view.addSubview(nameLabel)
        view.transform = CGAffineTransform(rotationAngle: (150 * (.pi/100)))
        return view
    }
}

