//
//  InfoVC.swift
//  USSoccer
//
//  Created by Jared Sobol on 1/3/18.
//  Copyright © 2018 Appmaker. All rights reserved.
//

import UIKit

class InfoVC: UIViewController {

    @IBOutlet weak var infoView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        infoView.layer.cornerRadius = 10
        infoView.layer.masksToBounds = true
    }

    @IBAction func cancelBtnPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func appKeyBtnPressed(_ sender: Any) {
        
        
    }
    @IBAction func appFeaturesBtnPressed(_ sender: Any) {
        
    }

    @IBAction func backBtnPressed(_ sender: Any) {
        
    }
    
}
