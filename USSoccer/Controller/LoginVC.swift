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
        let cleanedupStrings = trimmedandUnwrappedUserPass(email: emailTextField.text, password: passwordTxtField.text)
        firebaseAuthErrorHandling(emailString: cleanedupStrings.0, passString: cleanedupStrings.1)
        
    }
    
    @IBAction func fogotPasswordBtnClicked(_ sender: Any) {
    }
    
    @IBAction func signUpBtnClicked(_ sender: Any) {
        let cleanedupStrings = trimmedandUnwrappedUserPass(email: emailTextField.text, password: passwordTxtField.text)
        let isvalid = firebaseAuthErrorHandling(emailString: cleanedupStrings.0, passString: cleanedupStrings.1)
        if isvalid {
            Auth.auth().createUser(withEmail: cleanedupStrings.0, password: cleanedupStrings.1) { (user, error) in
                if error == nil {
                    
                }
                let firebaseError = error! as NSError
                    switch firebaseError.code {
                    case AuthErrorCodesFirebase.Error_Invalid_Email.rawValue:
                        print(firebaseError.code)
                        print(error)
                        let invalidEmailAlert = loginAuthAlertMaker(alertTitle: "Invalid Email", alertMessage: "Please enter a valid Email Address")
                        self.present(invalidEmailAlert, animated: true, completion: nil)
                    case AuthErrorCodesFirebase.Error_Email_Already_In_Use.rawValue:
                        let emailAlreadyInUseAlert = loginAuthAlertMaker(alertTitle: "Email is Already in Use", alertMessage: "This email is already in use")
                        self.present(emailAlreadyInUseAlert, animated: true, completion: nil)
                    default:
                        print(firebaseError.code)
                        print(error)
                    }
//                var firebaseError = error! as NSError
//                if firebaseError.code == AuthErrorCodesFirebase.Error_Invalid_Email.rawValue  {
//
//                }
//                if let error = error {
//                    let firebaseError = error as NSError
//                    if firebaseError.code == AuthErrorCodesFirebase.Error_Invalid_Email.rawValue  {
//
//                    }
//                    print(firebaseError.userInfo["error_name"])
//                } else {
//                    print("Created Valid User")
//                }
                /*
                if error == nil {
                    print("Created Valid User")
                } else if error.code == "ERROR_INVALID_EMAIL" {
                    let invaildEmailAlert = loginAuthAlertMaker(alertTitle: "Invaild Email", alertMessage: "Please Enter a valid Email")
                    self.present(invaildEmailAlert, animated: true, completion: nil)
                }
                print(error) */
            }
        }
//        print(cleanedupStrings.0)
//        print(cleanedupStrings.1)
    }
      
    
    func firebaseAuthErrorHandling(emailString: String, passString: String) -> Bool {
        let stringTuple = (emailString, passString)

        switch stringTuple {
        case (let x, let y) where x.isEmpty && y.isEmpty:
            let emptyEmailAndPassAlert = loginAuthAlertMaker(alertTitle: "Empty Email & Password", alertMessage: "Please enter your Email & Password")
            self.present(emptyEmailAndPassAlert, animated: true, completion: nil)
            return false
        case (let x,_) where x.isEmpty:
            let emptyEmailAlert = loginAuthAlertMaker(alertTitle: "Empty Email", alertMessage: "Please enter your Email")
            self.present(emptyEmailAlert, animated: true, completion: nil)
            return false
        case (_, let y) where y.isEmpty:
            let emptyPasswordAlert = loginAuthAlertMaker(alertTitle: "Empty Password", alertMessage: "Please enter your Password")
            self.present(emptyPasswordAlert, animated: true, completion: nil)
            return false
        default:
            return true
        }
    }
    
    func trimmedandUnwrappedUserPass(email: String?, password: String?) -> (String,String) {
        let trimmedEmail = stringTrimmer(stringToTrim: email)
        let trimmedPassword = stringTrimmer(stringToTrim: password)
        guard let unwrappedTrimmedEmail = trimmedEmail else {return ("","")}
        guard let unwrappedTrimmedPassword = trimmedPassword else {return ("","")}
        return (unwrappedTrimmedEmail, unwrappedTrimmedPassword)
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

