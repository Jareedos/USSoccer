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
    
    var sortedGames = [String: [SoccerGame]]()
    let appenderArray = [SoccerGame]()
    
    override func viewDidAppear(_ animated: Bool) {
        let soccerBall = #imageLiteral(resourceName: "football-ball")
        var imageView = UIImageView(image: soccerBall)
        self.view.addSubview(imageView)
        imageView.frame = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2 , width: 100, height: 100)

        // call Api and Parse it
//        ApiCaller.shared.ApiCall()
        
        gamesRef.observe(.value, with: { snapshot in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let game = SoccerGame(snapShot: child)
                
                // Sorting Games into a Dictionary to use on HomeVC
                let teamsTitles = game.title.components(separatedBy: "vs")
                let trimmedTitle = stringTrimmer(stringToTrim: teamsTitles[0].uppercased())
                
                if var appenderArray = self.sortedGames[trimmedTitle!] {
                    appenderArray.append(game)
                    self.sortedGames[trimmedTitle!] = appenderArray
                } else {
                    self.sortedGames[trimmedTitle!] = [game]
                }
            }
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "loadingToHome", sender: nil)
            }
        })
    }

//    func addSoccerBall() {
//       layer.addSublayer(soccerBall)
//    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let toDoItemToPass = sortedGames
        if let navc = segue.destination as? UINavigationController,
            let detailViewController = navc.viewControllers.first as? HomeVC {
            
            detailViewController.sortedGames = toDoItemToPass
        }
        
    }

}
