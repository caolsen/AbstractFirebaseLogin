//
//  AuthenticationResult.swift
//  AbstractFirebaseLogin
//
//  Created by Christopher Olsen on 3/7/18.
//  Copyright © 2018 Christopher Olsen. All rights reserved.
//

import Foundation

/// Result to return after all authentication attempts.
///
/// - success: Success authentication, contains User object
/// - failure: Failed authentication, contains Error
/// - noAccount: No account exists for email authentication, contains email string
/// - wrongProvider: Authentication was attempted with the wrong account provider, contains correct provider to use
/// - preflightSuccess: Preflight check for email address was successful, contains email
public enum AuthenticationResult {
    case success(User?)
    case failure(Error)
    case noAccount(String)
    case wrongProvider(useProvider: AccountProvider, withEmail: String)
    case preflightSuccess(String)
}
