//
//  LoadingVC.swift
//  USSoccer
//
//  Created by Jared Sobol on 11/11/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit
import FirebaseDatabase

class LoadingVC: UIViewController {
    
    @IBOutlet weak var loadingLbl: UILabel!
    var sortedGames = [String: [SoccerGame]]()
    let appenderArray = [SoccerGame]()
    
    override func viewDidAppear(_ animated: Bool) {
        // call Api and Parse it
        ApiCaller.shared.ApiCall()
        
        gamesRef.observe(.value, with: { snapshot in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                print(child, "child")
                let game = SoccerGame(snapShot: child)
                print(game, "game")
                
                // Sorting Games into a Dictionary to use on HomeVC
                let teamsTitles = game.title.components(separatedBy: "vs")
                let trimmedTitle = stringTrimmer(stringToTrim: teamsTitles[0].uppercased())
                
                if var appenderArray = self.sortedGames[trimmedTitle!] {
                    appenderArray.append(game)
                    self.sortedGames[trimmedTitle!] = appenderArray
                } else {
                    self.sortedGames[trimmedTitle!] = [game]
                }

                // Setting Up Time Stamps
//                let formatter = DateFormatter()
//                if game.timestamp == nil {
//                    let timeWithoutTimeZoneString = (game.time as NSString).substring(to: game.time.count - 2)
//
//                    let dateAndTimeStringWithProperTimeZone = game.date + " " + timeWithoutTimeZoneString + self.timezoneFromTimeString(timeString: game.time)
//
//                    // Date parsing, Time parsing
//                    formatter.dateFormat = "MMMM dd, yyyy h:mm a ZZZ"
//                    let date = formatter.date(from: dateAndTimeStringWithProperTimeZone)
//                    gamesRef.child(child.key).child("timestamp").setValue(date?.timeIntervalSince1970)
//                }
            }
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "loadingToHome", sender: nil)
            }
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func timezoneFromTimeString(timeString: String) -> String {
        // Default Eastern Time Zone -0500
        let timeZoneString = (timeString as NSString).substring(from: timeString.count - 2)
        
        switch timeZoneString {
        case "ET":
            return "-0500"
        case "CT":
            return "-0600"
        case "MT":
            return "-0700"
        case "PT":
            return "-0800"
        default:
            return "-0500"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let toDoItemToPass = sortedGames
        if let navc = segue.destination as? UINavigationController,
            let detailViewController = navc.viewControllers.first as? HomeVC {
            
            detailViewController.sortedGames = toDoItemToPass
        }
        
    }

}
