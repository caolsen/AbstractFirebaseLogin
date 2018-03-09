//
//  SignupViewController.swift
//  AbstractFirebaseLogin
//
//  Created by Christopher Olsen on 3/9/18.
//  Copyright © 2018 Christopher Olsen. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func signupButtonPressed(_ sender: UIButton) {
        signup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text = nil
        passwordTextField.text = nil
    }
    
    private func signup() {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            print("MUST ENTER A VALID EMAIL AND PASSWORD")
            return
        }
        
        AuthManager.sharedInstance.signup(email: email, password: password) { (user, error) in
            if let error = error {
                print("SIGN UP ERROR: " + error.localizedDescription)
            }
            
            guard let user = user else {
                return
            }
            
            print("SIGN UP SUCCESS: " + user.uid)
            self.performSegue(withIdentifier: SegueIdentifiers.loginComplete, sender: self)
        }
    }
}
