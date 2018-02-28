//
//  NavigationService.swift
//  USSoccer
//
//  Created by Jared Sobol on 2/13/18.
//  Copyright © 2018 Appmaker. All rights reserved.
//

import Foundation
import UIKit

enum NotificationAction: String {
    case openGame = "open_game"
}

class NavigationService {
    static let shared = NavigationService()
    private init() {}
    
    var pendingNotificationsData = [[String : Any]]()
    
    func handleAllPendingNotificationsData() {
        for data in pendingNotificationsData {
            handle(notificationData: data)
        }
        pendingNotificationsData.removeAll()
    }
    
    func handle(notificationData: [String : Any]) {
        if g_isLoadingData {
            pendingNotificationsData.append(notificationData)
            return
        }
        
        guard let ac = notificationData["action"] as? String, let action = NotificationAction(rawValue: ac) else {
            return
        }
        
        switch action {
        case .openGame:
            if let gameKey = notificationData["gameKey"] as? String {
                navigate(toGameKey: gameKey)
            }
        }
        
    }
    
    func navigate(toGameKey gameKey: String) {
        // Fetch the locally stored game
        if let soccerGame = CoreDataService.shared.fetchGames().filter( { (game) -> Bool in
            return game.gameKey == gameKey
        }).first {
            navigate(toGame: soccerGame)
        }
        
    }
    
    func navigate(toGame soccerGame: SoccerGame) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GameDetailVC") as! GameDetailVC
        vc.soccerGame = soccerGame
        show(viewController: vc, animated: true)
    }
    
    
    /**
     Shows the given View Controller based on the current top VC, we are simulating the "Show" segue
     */
    func show(viewController: UIViewController, animated: Bool, completion: (()->Void)? = nil) {
        if let _ = UIViewController.topMostController().navigationController {
            // Push
            push(viewController: viewController, animated: animated, completion: completion)
        } else {
            // Present Modally
            presentModally(viewController: viewController, animated: animated, completion: completion)
        }
    }
    
    func push(viewController: UIViewController, animated: Bool, completion: (()->Void)? = nil) {
        if let nc = UIViewController.topMostController().navigationController {
            // Push
            nc.pushViewController(viewController, animated: true)
            if let completion = completion {
                if animated {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.31, execute: completion)
                } else {
                    completion()
                }
            }
        }
    }
    
    func presentModally(viewController: UIViewController, animated: Bool, completion: (()->Void)? = nil) {
        let nc = UINavigationController(rootViewController: viewController)
        //viewController.addCloseButton()
        UIViewController.topMostController().present(nc, animated: animated, completion: completion)
    }
    
    
}
