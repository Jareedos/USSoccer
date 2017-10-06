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
        // Look below in utility section for trimmedAndUnwrappedUserPass func
        let cleanedupStrings = trimmedAndUnwrappedUserPass(email: emailTextField.text, password: passwordTxtField.text)
        // Look in Utility file for firebaseAuthErrorHangling func
        firebaseAuthErrorHandling(emailString: cleanedupStrings.0, passString: cleanedupStrings.1)
        
    }
    
    @IBAction func fogotPasswordBtnClicked(_ sender: Any) {
    }
    
    @IBAction func signUpBtnClicked(_ sender: Any) {
        // Look below in utility section for trimmedAndUnwrappedUserPass func
        let cleanedupStrings = trimmedAndUnwrappedUserPass(email: emailTextField.text, password: passwordTxtField.text)
        // Look in Utility file for firebaseAuthErrorHangling func
        let isvalid = firebaseAuthErrorHandling(emailString: cleanedupStrings.0, passString: cleanedupStrings.1)
        if isvalid {
            Auth.auth().createUser(withEmail: cleanedupStrings.0, password: cleanedupStrings.1) { (user, error) in
                if error == nil {
                    
                }
                let firebaseError = error! as NSError
                    switch firebaseError.code {
                    case AuthErrorCodesFirebase.error_Invalid_Email.rawValue:
                        let invalidEmailAlert = loginAuthAlertMaker(alertTitle: "Invalid Email", alertMessage: "Please enter a valid Email Address")
                        self.present(invalidEmailAlert, animated: true, completion: nil)
                    case AuthErrorCodesFirebase.error_Email_Already_In_Use.rawValue:
                        let emailAlreadyInUseAlert = loginAuthAlertMaker(alertTitle: "Email is Already in Use", alertMessage: "This email is already in use")
                        self.present(emailAlreadyInUseAlert, animated: true, completion: nil)
                    case AuthErrorCodesFirebase.error_Weak_Password.rawValue:
                        let weakPasswordAlert = loginAuthAlertMaker(alertTitle: "Weak Password", alertMessage: " Password Must Be atleast 6 characters long")
                        self.present(weakPasswordAlert, animated: true, completion: nil)
                    default:
                        print(firebaseError.code)
                        print(error)
                    }
            }
        }
    }
      
//UTILITY FUNCS FOR LOGINVC
//*************************
    
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
    
    
    func trimmedAndUnwrappedUserPass(email: String?, password: String?) -> (String,String) {
        //look in Utility file for stringTrimmer Func
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

