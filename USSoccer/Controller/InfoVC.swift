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
    @IBOutlet weak var appKeyBtn: UIButton!
    @IBOutlet weak var appFeaturesBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        infoView.layer.cornerRadius = 10
        infoView.layer.masksToBounds = true
        appKeyBtn.layer.cornerRadius = 10
        appKeyBtn.layer.masksToBounds = true
        appFeaturesBtn.layer.cornerRadius = 10
        appFeaturesBtn.layer.masksToBounds = true
    }

    @IBAction func cancelBtnPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func appKeyBtnPressed(_ sender: Any) {
        appKeyBtn.isHidden = true
        appFeaturesBtn.isHidden = true
        backBtn.isHidden = false
        
    }
    @IBAction func appFeaturesBtnPressed(_ sender: Any) {
        appKeyBtn.isHidden = true
        appFeaturesBtn.isHidden = true
        backBtn.isHidden = false
    }

    @IBAction func backBtnPressed(_ sender: Any) {
        backBtn.isHidden = true
        appKeyBtn.isHidden = false
        appFeaturesBtn.isHidden = false
    }
    
}
