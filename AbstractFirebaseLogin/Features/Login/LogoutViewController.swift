//
//  LogoutViewController.swift
//  AbstractFirebaseLogin
//
//  Created by Christopher Olsen on 3/9/18.
//  Copyright © 2018 Christopher Olsen. All rights reserved.
//

import UIKit

class LogoutViewController: UIViewController {

    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        attemptToLogoutUser()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let email = AuthManager.sharedInstance.currentUser?.email {
            print("USER EMAIL: " + email)
        }
    }
    
    private func attemptToLogoutUser() {
        AuthManager.sharedInstance.logout { (success) in
            if success {
                print("LOGOUT SUCCESSFUL")
                self.dismiss(animated: true, completion: nil)
                return
            }
            
            print("LOGOUT FAILURE")
        }
    }
}
