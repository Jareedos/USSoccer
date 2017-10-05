//
//  LoginVC.swift
//  USSoccer
//
//  Created by Jared Sobol on 10/4/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginVC: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTxtField: UITextField!

 
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginBtnClicked(_ sender: Any) {
        firebaseAuthErrorHandling(emailString: emailTextField.text, passString: passwordTxtField.text)

    }
    
    @IBAction func fogotPasswordBtnClicked(_ sender: Any) {
    }
    
    @IBAction func signUpBtnClicked(_ sender: Any) {
        firebaseAuthErrorHandling(emailString: emailTextField.text, passString: passwordTxtField.text)

    }
    
    func firebaseAuthErrorHandling(emailString: String?, passString: String?) {
        let trimmedEmail = stringTrimmer(stringToTrim: emailTextField.text)
        let trimmedPassword = stringTrimmer(stringToTrim: passwordTxtField.text)
        guard let unwrappedTrimmedEmail = trimmedEmail else {return}
        guard let unwrappedTrimmedPassword = trimmedPassword else {return}
        let stringTuple = (unwrappedTrimmedEmail, unwrappedTrimmedPassword)

        switch stringTuple {
        case (let x, let y) where x.isEmpty && y.isEmpty:
            let emptyEmailAndPassAlert = loginAuthAlertMaker(alertTitle: "Empty Email & Password", alertMessage: "Please enter your Email & Password")
            self.present(emptyEmailAndPassAlert, animated: true, completion: nil)
        case (let x,_) where x.isEmpty:
            let emptyEmailAlert = loginAuthAlertMaker(alertTitle: "Empty Email", alertMessage: "Please enter your Email")
            self.present(emptyEmailAlert, animated: true, completion: nil)
        case (_, let y) where y.isEmpty:
            let emptyPasswordAlert = loginAuthAlertMaker(alertTitle: "Empty Password", alertMessage: "Please enter your Password")
            self.present(emptyPasswordAlert, animated: true, completion: nil)
        default:
                print("Sorry")
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
