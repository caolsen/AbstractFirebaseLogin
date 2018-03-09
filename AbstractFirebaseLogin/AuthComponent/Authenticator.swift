//
//  Authenticator.swift
//  AbstractFirebaseLogin
//
//  Created by Christopher Olsen on 2/21/18.
//  Copyright © 2018 Christopher Olsen. All rights reserved.
//
//  Protocol that defines the public facing interface for AuthManager.
//  This will help with creating mocks for unit testing.
//

import UIKit

public protocol Authenticator {
    var currentUser: User? { get }
    var googleClientId: String? { get set }
    
    weak var delegate: AuthManagerDelegate? { get set }
    weak var uiDelegate: AuthManagerUIDelegate? { get set }
    
    func signup(email: String, password: String, completion: @escaping(User?, Error?) -> Void)
    
    func login(withEmail email: String, password: String)
    func loginWithGoogle()
    func loginWithFacebook(from viewController: UIViewController)
    
    func logout(completion: @escaping(_ success: Bool) -> Void)
    
    func handleGoogleSignIn(url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool
    func handleFacebookSignIn(app: UIApplication, url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool
    func enableFacebookLogin(with application: UIApplication, andLaunchOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)
    
    func getToken(completion: @escaping((token: String?, error: Error?)) -> Void)
    
    func resetPassword(email: String, completion: @escaping(_ error: Error?) -> Void)
    func reauthenticateUser(email: String, password: String, completion: @escaping(_ error: Error?) -> Void)
    func changePassword(newPassword: String, completion: @escaping(_ error: Error?) -> Void)
}
