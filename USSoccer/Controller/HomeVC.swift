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

class HomeVC: UIViewController {
    
    @IBOutlet weak var notificationAlertLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var teamPicker: UIPickerView!
    @IBOutlet weak var notificationLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var notificationMenuTrailingConstraint: NSLayoutConstraint!
    var pickerTeamsArray = ["U-15 MNT", "U-16 MNT", "U-17 MNT", "U-18 MNT", "U-19 MNT", "U-20 MNT", "U-23 MNT", "MNT", "ALL TEAMS", "WNT", "U-23 WNT", "U-20 WNT", "U-19 WNT", "U-18 WNT", "U-17 WNT", "U-16 WNT", "U-15 WNT"]
    var rotationAngle: CGFloat!
    let customHeight: CGFloat = 100
    let customWidth: CGFloat = 100
    var filterValue: String!
    var sortedGames = [String: [SoccerGame]]()
    var soccerGames = [SoccerGame]()
    var teamArray = [Team]()
    
    var notificationAlertVisible = false
    var notificationMenuVisible = false
    var notificationAlertHideTimer : Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        rotationAngle = -150 * (.pi/100)
        teamPicker.delegate = self
        teamPicker.dataSource = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        teamPicker.transform = CGAffineTransform(rotationAngle: rotationAngle)
        teamPicker.frame = CGRect(x: -100, y: view.frame.height - 73, width: view.frame.width + 200, height: 68)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFont(name: "HelveticaNeue-CondensedBold", size: 22.0)!,NSAttributedStringKey.foregroundColor: UIColor.white]
        
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
        tableView.reloadData()
        
        
        notificationLeadingConstraint.constant = UIScreen.main.bounds.size.width
        notificationMenuTrailingConstraint.constant = 187
        view.layoutIfNeeded()
    }
    
    @IBAction func notificationMenuSwipedOff(_ sender: Any) {
        
        notificationMenuTrailingConstraint.constant = 187
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }) { (finished: Bool) in
            self.notificationMenuVisible = false
        }
        
    }
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return soccerGames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GamesTVCell", for: indexPath) as? GamesTVCell else {
            fatalError("The Cell Failed to Deque")
        }
        cell.notificationBtn.tag = indexPath.row
        cell.notificationBtn.addTarget(self, action: #selector(notificationButtonClicked(sender:)), for: .touchUpInside)
        cell.gameTimeLbl.text = "3:30PM ET"
        let usSoccerTitle = soccerGames[indexPath.row].title.components(separatedBy: " ")
        
        
        if usSoccerTitle[1] != "vs" {
            cell.gameTitleLbl.text = "\(usSoccerTitle[0].uppercased()) \(usSoccerTitle[1].uppercased())"
            cell.vsLbl.text = "\(usSoccerTitle[2].uppercased())"
            cell.opponentLbl.text = "\(usSoccerTitle[3].uppercased())"
        } else {
            cell.gameTitleLbl.text = "\(usSoccerTitle[0].uppercased())"
            cell.vsLbl.text = "\(usSoccerTitle[1].uppercased())"
            cell.opponentLbl.text = "\(usSoccerTitle[2].uppercased())"
        }
        
        let soccerGame = soccerGames[indexPath.row]
        if let team = team(forGame: soccerGame) {
            
            if team.notifications == true {
                cell.notificationBtn.setImage(UIImage(named: "bell-musical-tool (1)"), for: .normal)
            } else {
                cell.notificationBtn.setImage(UIImage(named: "musical-bell-outline (2)"), for: .normal)
            }
        }
        
        let gameDate = soccerGames[indexPath.row].date.components(separatedBy: " ")
        let formatedMonth = gameDate[0].prefix(3)
        cell.gameDateLbl.text = "\(formatedMonth.uppercased()) \(gameDate[1]) \(gameDate[2])"
        let date = soccerGames[indexPath.row].timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        let strDate = dateFormatter.string(from: date!)
        cell.gameTimeLbl.text = strDate
        
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
        
        notificationMenuTrailingConstraint.constant = 0.0
        notificationLeadingConstraint.constant = UIScreen.main.bounds.size.width
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }, completion: { (finished: Bool) in
            self.notificationMenuVisible = true
            self.notificationAlertVisible = false
        })
    }
    
    @objc func notificationAlertHideTimerFired() {
        // Hide after some time
        UIView.animate(withDuration: 0.3, animations: {
            self.notificationLeadingConstraint.constant = UIScreen.main.bounds.size.width
            self.view.layoutIfNeeded()
        }, completion: { (finished: Bool) in
            self.notificationAlertVisible = false
        })
    }
    
    @objc func notificationButtonClicked(sender: UIButton) {
        
        let buttonPosition = sender.convert(CGPoint.zero, to: tableView)
        let indexPath: IndexPath! = tableView.indexPathForRow(at: buttonPosition)
        
        let game = soccerGames[indexPath.row]
        if let team = team(forGame: game) {
            team.notifications = !team.notifications
            team.twoHour = !team.twoHour
            CoreDataService.shared.saveContext()
            
            // Change text on Alert to match
            notificationAlertLbl.text = "\(team.title?.uppercased() ?? "Name not available") Notification Set"
            
            //Now change the text and background colour
            if team.notifications {
                notificationAlertVisible = !notificationAlertVisible
                if notificationAlertVisible {
                    // Showing
                    notificationLeadingConstraint.constant = 0.0
                    UIView.animate(withDuration: 0.3, animations: {
                        self.view.layoutIfNeeded()
                    }, completion: { (finished: Bool) in
                        
                        self.notificationAlertHideTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(HomeVC.notificationAlertHideTimerFired), userInfo: nil, repeats: false)
                    })
                    
                } else {
                    // Hiding
                    notificationLeadingConstraint.constant = UIScreen.main.bounds.size.width
                    UIView.animate(withDuration: 0.3) {
                        self.view.layoutIfNeeded()
                    }
                }
            }
        }
        
        
        tableView.reloadData()
//        cell.button.backgroundColor = UIColor.blueColor()
        print("I got here")
        
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
        filterValue = pickerTeamsArray[row]
        soccerGames = sortedGames[filterValue] ?? [SoccerGame]()
        tableView.reloadData()
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

