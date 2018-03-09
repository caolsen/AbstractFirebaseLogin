//
//  AuthManager.swift
//  AbstractFirebaseLogin
//
//  Created by Christopher Olsen on 2/21/18.
//  Copyright © 2018 Christopher Olsen. All rights reserved.
//
//  This is the central auth class. It encapsulates all login functionality
//  for Firebase, including Google and Facebook.
//
//  It contains quite a few functions and properties that exists simply as wrappers for
//  sign-in functionality. This helps keep the various login libraries isolated from
//  the main app code.
//

import Foundation
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

typealias WrongProviderResponse = (wrongProvider: Bool, email: String?)

enum AuthError: Error {
    case noFacebookAccessToken
    case noAccountProvider
}

public class AuthManager: NSObject, Authenticator {
    
    /// Singleton Instance
    public static let sharedInstance = AuthManager()
    
    // MARK: Instance Properties
    
    /// Delegate used for all callbacks from the AuthManager
    public weak var delegate: AuthManagerDelegate?
    
    /// Wrapper for Google Sign-in uiDelegate. This needs to be set to a UIViewController
    /// prior to the user attemping to log in to Google.
    public weak var uiDelegate: AuthManagerUIDelegate? {
        didSet {
            GIDSignIn.sharedInstance().uiDelegate = uiDelegate
        }
    }
    
    /// Wrapper for Google Sign in clientId
    /// This way the app doesn't need to import GoogleSignIn
    public var googleClientId: String? {
        didSet {
            GIDSignIn.sharedInstance().clientID = googleClientId
        }
    }
    
    // MARK: Computed Properties
    
    /// Current User from Firebase, if one exists
    public var currentUser: User? {
        if let user = Auth.auth().currentUser {
            return User(uid: user.uid, email: user.email, creationDate: user.metadata.creationDate, lastSignInDate: user.metadata.lastSignInDate)
        } else {
            return nil
        }
    }
    
    /// Current user's account provider or nil if none exists
    public var accountType: AccountProvider? {
        guard let accountType = Auth.auth().currentUser?.providerData.first?.providerID else {
            return nil
        }
        
        return AccountProvider(rawValue: accountType)
    }
    
    // MARK: Inits
    
    private override init() {
        super.init()
        GIDSignIn.sharedInstance().delegate = self
    }
    
    // MARK: Signup
    
    /// Signs up new user to Firebase with email
    public func signup(email: String, password: String, completion: @escaping(User?, Error?) -> Void) {
        
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            Auth.auth().currentUser?.sendEmailVerification()
            
            completion(self.currentUser, error)
        }
    }
    
    // MARK: Public Auth Functions
    
    /// Wrapper around Google sign in. This will open the OAuth dialog which will
    /// eventually continue execution in the Google delegate functions.
    public func loginWithGoogle() {
        GIDSignIn.sharedInstance().signIn()
    }
    
    /// Wrapper around Facebook Sign in. Will open OAuth dialog.
    ///
    /// - Parameter viewController: UIViewController that handles displaying the OAuth view
    public func loginWithFacebook(from viewController: UIViewController) {
        FBSDKLoginManager().logIn(withReadPermissions: ["email"], from: viewController, handler: { (result, error) in
            if let error = error {
                self.delegate?.authComplete(with: .failure(error), forAccount: .facebook)
                return
            }
            
            guard FBSDKAccessToken.current() != nil else {
                self.delegate?.authComplete(with: .failure(AuthError.noFacebookAccessToken), forAccount: .facebook)
                return
            }
            
            self.login(withFacebookToken: FBSDKAccessToken.current().tokenString)
        })
    }
    
    /// Logs in to firebase with Email and Password. Will call the delegate function
    /// authComplete(with:forAccount:) when complete.
    ///
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    public func login(withEmail email: String, password: String) {
        checkEmail(email, emailOk: {
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                self.delegate?.authComplete(with: .success(self.currentUser), forAccount: .email)
            }
        })
    }
    
    /// Checks email availability. If email is not in use with a social login provider and
    /// has been registered with Firebase this will call authComplete with .preflightSuccess
    /// which indicates the email is safe to attempt login with via email authentication.
    ///
    /// - Parameter email: email to check
    public func checkEmailAvailability(_ email: String) {
        checkEmail(email, emailOk: {
            self.delegate?.authComplete(with: .preflightSuccess(email), forAccount: .email)
        })
    }
    
    /// Attempts to log the user out of Firebase, Google, and Facebook
    ///
    /// - Parameter completion: called after logout is attempted
    public func logout(completion: @escaping(_ success: Bool) -> Void) {
        
        FBSDKLoginManager().logOut()
        GIDSignIn.sharedInstance().signOut()
        
        // Actual signout
        do {
            try Auth.auth().signOut()
            completion(true)
        } catch {
            completion(false)
        }
    }
    
    // MARK: Private Auth Functions
    
    /// Get Facebook login credential and login via Firebase
    private func login(withFacebookToken token: String) {
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        login(withSocialProvider: .facebook, and: credential)
    }
    
    
    /// Get Google login credential and login via Firebase
    fileprivate func login(withGoogleIdToken idToken: String, accessToken: String) {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        login(withSocialProvider: .google, and: credential)
    }
    
    /// Central login function for social media accounts (Facebook and Google). Attempts to log the
    /// user into Firebase using the OAuth credential. Will call one of 2 delegate functions:
    ///  loginComplete(user:error:) - will be called if login is attempted with correct provider
    ///  userShouldLogin(with:) - will be called if the user should use a different provider
    ///
    /// - Parameters:
    ///   - provider: provider the user is attempting to login with
    ///   - credential: OAuth credential for Facebook or Google
    private func login(withSocialProvider provider: AccountProvider, and credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { (user, error) in
            
            // If there isn't an error we can just call the delegate and return
            guard let error = error else {
                self.delegate?.authComplete(with: .success(self.currentUser), forAccount: provider)
                return
            }
            
            // If there is an error logging into Firebase we log the user out of the social media SDKs
            FBSDKLoginManager().logOut()
            GIDSignIn.sharedInstance().signOut()
            
            // Check to see if the error occured because the user used the wrong provider
            let wrongProviderResponse = self.doesErrorContainWrongProvider(error, compareTo: provider)
            
            // If there's no email we can't tell if the wrong provider was used
            guard let email = wrongProviderResponse.email else {
                self.delegate?.authComplete(with: .failure(error), forAccount: provider)
                return
            }
            
            guard wrongProviderResponse.wrongProvider else {
                self.delegate?.authComplete(with: .failure(error), forAccount: provider)
                return
            }
            
            self.getCorrectProvider(with: provider, andEmail: email) { (result) in
                do {
                    if let correctProvider = try result.resolve() {
                        let authResult = AuthenticationResult.wrongProvider(useProvider: correctProvider, withEmail: email)
                        self.delegate?.authComplete(with: authResult, forAccount: provider)
                    } else {
                        self.delegate?.authComplete(with: .failure(error), forAccount: provider)
                    }
                } catch {
                    self.delegate?.authComplete(with: .failure(error), forAccount: provider)
                }
            }
        }
    }
    
    // MARK: Provider Functions
    
    /// Uses the email to check Firebase for:
    ///  - if the email is already in use with a social login provider
    ///  - if the email has never been used
    ///  - if the email is already registered with FirebaseAuth
    ///
    /// - Parameters:
    ///   - email: email to check
    ///   - emailOk: closure to execute if the email is registered with FirebaseAuth
    private func checkEmail(_ email: String, emailOk: @escaping() -> Void) {
        getCorrectProvider(with: .email, andEmail: email) { (result) in
            do {
                if let provider = try result.resolve() {
                    let authResult = AuthenticationResult.wrongProvider(useProvider: provider, withEmail: email)
                    self.delegate?.authComplete(with: authResult, forAccount: .email)
                } else {
                    emailOk()
                }
            } catch AuthError.noAccountProvider {
                self.delegate?.authComplete(with: .noAccount(email), forAccount: .email)
            } catch {
                self.delegate?.authComplete(with: .failure(error), forAccount: .email)
            }
        }
    }
    
    /// It's possible for users to log in with the wrong provider. E.g. A user creates an intial account with
    /// Google, but then later tries to log in with just their email. This causes problems with Firebase if
    /// the user's initial signup was with email.
    ///
    /// To mitigate this we check if they are using the correct provider here.
    ///
    ///   - error: The error object from Google or Facebook login attempt
    ///   - provider: The provider the user is attempting to login with
    /// - Returns: (wrongProvider: Is the user attempting the wrong provider, email: email attempting to login with)
    private func doesErrorContainWrongProvider(_ error: Error, compareTo provider: AccountProvider) -> WrongProviderResponse {
        if let email = (error as NSError).userInfo["FIRAuthErrorUserInfoEmailKey"] as? String {
            return (true, email)
        } else {
            return (false, nil)
        }
    }
    
    /// Checks Firebase to get the initial provider used to create user account.
    ///
    /// - Parameters:
    ///   - provider: Provider the user is attempting to log in with
    ///   - email: User's email
    ///   - completion: completion block, provider will be nil if the correct provider is already being used
    private func getCorrectProvider(with provider: AccountProvider, andEmail email: String, completion: @escaping(Result<AccountProvider?>) -> Void) {
        fetchProviders(forEmail: email) { (initialProvider, error) in
            completion(Result {
                if let error = error {
                    throw error
                }
                
                guard let initialProvider = initialProvider else {
                    throw AuthError.noAccountProvider
                }
                
                if provider != initialProvider {
                    // wrong provider is being used
                    return initialProvider
                } else {
                    // already using the correct provider
                    return nil
                }
            })
        }
    }
    
    /// Returns service that user created account with or nil if they don't have an account.
    ///
    /// - Parameters:
    ///   - email: Email string for the user attmepting to log in
    ///   - completion: Contains the first matching account type and a possible error
    private func fetchProviders(forEmail email: String, completion: @escaping(AccountProvider?, Error?) -> Void) {
        Auth.auth().fetchProviders(forEmail: email, completion: { (providers, error) in
            
            guard let providerString = providers?.first else {
                completion(nil, error)
                return
            }
            
            completion(AccountProvider(rawValue: providerString), error)
        })
    }
    
    // MARK: Helper Functions
    
    /// Should be called from AppDelegate's application(_:open:options:) to handle the Google callback URL
    public func handleGoogleSignIn(url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url,
                                                 sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: options[UIApplicationOpenURLOptionsKey.annotation])
    }
    
    /// Should be called from AppDelegate's application(_:open:options:) to handle the Facebook callback URL
    public func handleFacebookSignIn(app: UIApplication, url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
    }
    
    /// Call in AppDelegate's application(_:didFinishLaunchingWithOptions:) to enable Facebook SDK
    public func enableFacebookLogin(with application: UIApplication, andLaunchOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    /// Return the user's token to make API requests to firebase, and forces a refresh
    /// - Parameter completion: Returns the token and an error (if they exist)
    public func getToken(completion: @escaping((token: String?, error: Error?)) -> Void) {
        
        if let currentUser = Auth.auth().currentUser {
            currentUser.getIDTokenForcingRefresh(true, completion: { (token, error) in
                completion((token, error))
            })
        } else {
            completion((nil, nil))
        }
    }
    
    public func resetPassword(email: String, completion: @escaping(_ error: Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: { (error) in
            completion(error)
        })
    }
    
    public func reauthenticateUser(email: String, password: String, completion: @escaping(_ error: Error?) -> Void) {
        
        let credentials = EmailAuthProvider.credential(withEmail: email, password: password)
        Auth.auth().currentUser?.reauthenticate(with: credentials, completion: { (authError) in
            completion(authError)
        })
    }
    
    public func changePassword(newPassword: String, completion: @escaping(_ error: Error?) -> Void) {
        Auth.auth().currentUser?.updatePassword(to: newPassword, completion: { (updateError) in
            completion(updateError)
        })
    }
}

// MARK: - GIDSignInDelegate
extension AuthManager: GIDSignInDelegate {
    
    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard let auth = user.authentication else { return }
        
        login(withGoogleIdToken: auth.idToken, accessToken: auth.accessToken)
    }
    
    public func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {}
}
