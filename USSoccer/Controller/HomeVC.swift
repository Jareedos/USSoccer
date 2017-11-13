//
//  HomeVC.swift
//  USSoccer
//
//  Created by Jared Sobol on 11/11/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit

class HomeVC: UIViewController {
    
    @IBOutlet weak var teamPicker: UIPickerView!
    let pickerTeamsArray = ["U-23 MNT", "MNT", "ALL TEAMS", "WNT", "U-23 WNT"]
    var rotaionAngle: CGFloat!
    let customHeight: CGFloat = 100
    let customWidth: CGFloat = 80

    override func viewDidLoad() {
        super.viewDidLoad()
        rotaionAngle = -150 * (.pi/100)
        teamPicker.delegate = self
        teamPicker.dataSource = self
        
        let y = teamPicker.frame.origin.y
        teamPicker.transform = CGAffineTransform(rotationAngle: rotaionAngle)
        teamPicker.frame = CGRect(x: -100, y: y, width: view.frame.width + 200, height: 50)
        teamPicker.selectRow(2, inComponent: 0, animated: true)
        // Do any additional setup after loading the view.
    }

}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GameTVCell", for: indexPath) as? GamesTVCell else {
            fatalError("The Cell Failed to Deque")
        }
        
        return cell
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
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: customWidth, height: customHeight))
        let nameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: customWidth, height: customHeight))
        nameLabel.text = pickerTeamsArray[row]
        nameLabel.textAlignment = .center
        nameLabel.textColor = UIColor(red:0.00, green:0.25, blue:0.53, alpha:1.0)
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        view.addSubview(nameLabel)
        view.transform = CGAffineTransform(rotationAngle: (150 * (.pi/100)))
        return view
    }
}

