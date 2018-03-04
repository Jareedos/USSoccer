//
//  UIViewControllerExtension.swift
//  USSoccer
//
//  Created by Jared Sobol on 1/27/18.
//  Copyright © 2018 Appmaker. All rights reserved.
//

import Foundation
import UIKit

extension UIAlertController {
    
    static func okAlertWithTitle(_ title: String, message: String?, okTapped: (()->Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in
            okTapped?()
        }))
        
        return alertController
    }
    
    static func presentOKAlertWithTitle(_ title: String, message: String?, okTapped: (()->Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController.okAlertWithTitle(title, message: message, okTapped: okTapped)
        let topVC = UIViewController.topMostController()
        if topVC.presentedViewController == nil {
            UIViewController.topMostController().present(alertController, animated: true, completion: nil)
        }
        return alertController
    }
    
    static func presentOKAlertWithError(_ error: NSError, okTapped: (()->Void)? = nil) -> UIAlertController {
        return presentOKAlertWithTitle(error.domain, message: error.localizedDescription)
    }
}


extension UIViewController {
    static func topMostController() -> UIViewController {
        
        let delegate = UIApplication.shared.delegate as? AppDelegate
        var topController: UIViewController = delegate!.window!.rootViewController!
        for _ in 0..<2 {
            while topController.presentedViewController != nil && topController.presentedViewController?.isKind(of: UIAlertController.self) == false {
                topController = topController.presentedViewController!
            }
            if (topController.isKind(of: UITabBarController.self)) {
                topController = ((topController as! UITabBarController)).selectedViewController!
            }
            if (topController.isKind(of: UINavigationController.self)) {
                topController = ((topController as! UINavigationController)).topViewController!
            }
        }
        return topController
    }
}
