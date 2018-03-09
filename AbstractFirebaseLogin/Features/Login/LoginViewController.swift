//
//  LoginViewController.swift
//  AbstractFirebaseLogin
//
//  Created by Christopher Olsen on 3/9/18.
//  Copyright © 2018 Christopher Olsen. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, AuthManagerUIDelegate {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        attemptToLoginUser()
    }
    
    @IBAction func loginWithGoogleButtonPressed(_ sender: UIButton) {
        attemptGoogleLogin()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AuthManager.sharedInstance.uiDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AuthManager.sharedInstance.delegate = self
        
        emailTextField.text = nil
        passwordTextField.text = nil
    }
    
    private func attemptToLoginUser() {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            print("MUST ENTER A VALID EMAIL AND PASSWORD")
            return
        }
        
        AuthManager.sharedInstance.login(withEmail: email, password: password)
    }
    
    private func attemptFacebookLogin() {
        AuthManager.sharedInstance.loginWithFacebook(from: self)
    }
    
    private func attemptGoogleLogin() {
        AuthManager.sharedInstance.loginWithGoogle()
    }
    
    private func presentRedirectAlert(withTitle title: String, message: String, andAction action: @escaping(UIAlertAction) -> Void) {
        let primaryAction = UIAlertAction(title: "Go", style: .default, handler: action)
        let secondaryAction = UIAlertAction(title: "cancel", style: .default, handler: nil)
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(primaryAction)
        alertController.addAction(secondaryAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func presentProviderAlert(_ provider: AccountProvider) {
        let message = "The email you used is already registered with a " + provider.rawValue + " account. Try logging in with that."
        let alertController = UIAlertController(title: "Wrong Account", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

extension LoginViewController: AuthManagerDelegate {
    func authComplete(with result: AuthenticationResult, forAccount provider: AccountProvider) {
        switch result {
        case .success(let user):
            guard let user = user else {
                return
            }
            
            print("LOGIN SUCCESSFUL: " + user.uid)
            self.performSegue(withIdentifier: SegueIdentifiers.loginComplete, sender: self)
        case .failure(let error):
            print("LOGIN ERROR: " + error.localizedDescription)
        case .noAccount(let email):
            presentRedirectAlert(withTitle: "You don't have an account", message: "Would you like to make one?") { [unowned self] (action) in
                self.performSegue(withIdentifier: SegueIdentifiers.showSignup, sender: self)
            }
            print("USER NEEDS TO SIGNUP USING EMAIL: " + email)
        case .wrongProvider(useProvider: let provider, withEmail: let email):
            presentProviderAlert(provider)
            print("USER SHOULD LOGIN WITH PROVIDER: " + provider.rawValue + " AND EMAIL: " + email)
        case .preflightSuccess(let email):
            print("EMAIL OK TO USE FOR LOGIN: " + email)
        }
    }
}
