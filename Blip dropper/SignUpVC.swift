//
//  ViewController.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 8/12/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.
//

import UIKit
import Parse

class SignUpVC: UIViewController {
    var signUpModeActive = true
    
    func displayAlert(title:String, message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {
            (action) in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert,animated: true, completion: nil)
    }
    
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var passWord: UITextField!
    @IBOutlet weak var logOnSignUpButton: UIButton!
    @IBOutlet weak var switchModeButton: UIButton!
    @IBOutlet weak var msgSignUpLogOn: UILabel!
    
    @IBAction func switchMode(_ sender: Any) {
        if (signUpModeActive) {
            signUpModeActive = false
            logOnSignUpButton.setTitle("Log In", for: [])
            switchModeButton.setTitle("Sign Up", for: [])
            msgSignUpLogOn.text = "New user? Create new account"
        } else {
            signUpModeActive = true
            logOnSignUpButton.setTitle("Sign Up", for: [])
            switchModeButton.setTitle("Log In", for: [])
            msgSignUpLogOn.text = "Already have an account?"
        }
    }

    @IBAction func logOnSignUp(_ sender: Any) {
        // Deactivate interactions when communicating with server
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        // Check that SOMETHING was entered (the server will check for valid email input later)
        if ( userName.text == "" || passWord.text == "" ){
            UIApplication.shared.endIgnoringInteractionEvents()
            activityIndicator.stopAnimating()
            displayAlert(title:"Error in form", message:"Please enter an email and a password")
        } else {
            if (signUpModeActive) {
                let user = PFUser()
                user.username = userName.text
                user.password = passWord.text
                user.email = userName.text
                // You can add other fields here just like with PFObject
                // e.g. user["phone"] = "415-392-0202"
                user.signUpInBackground { (succes, error) in
                    UIApplication.shared.endIgnoringInteractionEvents()
                    activityIndicator.stopAnimating()
                    if let error = error {
                        //let errorString = error.userInfo["error"] as? NSString
                        // Show the errorString somewhere and let the user try again.
                        print(error)
                        self.displayAlert(title:"Could not sign you up", message:error.localizedDescription)
                    } else {
                        print("signed up!")
                        // Signed up, show blips page
                        self.performSegue(withIdentifier: "showBlipFeed", sender: self)
                        print("ready to create the segue?")
                    }
                }
            } else {
                PFUser.logInWithUsername(inBackground: userName.text!, password: passWord.text!) { (user, error) in
                    UIApplication.shared.endIgnoringInteractionEvents()
                    activityIndicator.stopAnimating()
                    
                    if (user != nil) {
                        print("logon successful")
                        self.performSegue(withIdentifier: "showBlipFeed", sender: self)

                    } else {
                        var errorText = "Unknown error: please try again"
                        if let error = error {
                            errorText = error.localizedDescription
                        }
                        self.displayAlert(title: "Could not sign you on", message:errorText)
                    }
                }
            }
        }
    }
    
    @IBAction func dismissVC(segue: UIStoryboardSegue) {}
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewDidLoad.SignUpVC")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("ViewDidAppear.SignUpVC")
        if PFUser.current() != nil {
            print("Current User: \(PFUser.current()?.objectId ?? "")")
            print(time2String(time: Date()))
            self.performSegue(withIdentifier: "showBlipFeed", sender: self)
        }
        // are we using nav bars? self.navigationController?.navigationBar.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

