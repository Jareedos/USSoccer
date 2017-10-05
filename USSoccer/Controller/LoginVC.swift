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
        // see utility function stringTimmer
        let trimmedEmail = stringTrimmer(stringToTrim: emailTextField.text)
        let trimmedPassword = stringTrimmer(stringToTrim: passwordTxtField.text)
        
        if (trimmedEmail?.isEmpty)! {
            //see utility function loginAuthAlertMaker
            let emptyEmailAlert = loginAuthAlertMaker(alertTitle: "Empty Email", alertMessage: "Please enter your Email")
            self.present(emptyEmailAlert, animated: true, completion: nil)
        }
        
        if (trimmedPassword?.isEmpty)! {
            let emptyPasswordAlert = loginAuthAlertMaker(alertTitle: "Empty Password", alertMessage: "Please enter your Password")
            self.present(emptyPasswordAlert, animated: true, completion: nil)
        }
//        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
//        }
    }
    
    @IBAction func fogotPasswordBtnClicked(_ sender: Any) {
    }
    
    @IBAction func signUpBtnClicked(_ sender: Any) {
        let trimmedEmail = stringTrimmer(stringToTrim: emailTextField.text)
        let trimmedPassword = stringTrimmer(stringToTrim: passwordTxtField.text)
        
        if (trimmedEmail?.isEmpty)! {
            //see utility function loginAuthAlertMaker
            let emptyEmailAlert = loginAuthAlertMaker(alertTitle: "Empty Email", alertMessage: "Please enter your Email")
            self.present(emptyEmailAlert, animated: true, completion: nil)
        }
        
        if (trimmedPassword?.isEmpty)! {
            let emptyPasswordAlert = loginAuthAlertMaker(alertTitle: "Empty Password", alertMessage: "Please enter your Password")
            self.present(emptyPasswordAlert, animated: true, completion: nil)
        }
        
//        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
//        }
    }
    
//    func 
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
