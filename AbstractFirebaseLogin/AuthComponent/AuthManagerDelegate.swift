//
//  AuthManagerDelegate.swift
//  AbstractFirebaseLogin
//
//  Created by Christopher Olsen on 2/26/18.
//  Copyright © 2018 Christopher Olsen. All rights reserved.
//

import Foundation

public protocol AuthManagerDelegate: class {
    func authComplete(with result: AuthenticationResult, forAccount provider: AccountProvider)
}
