//
//  User.swift
//  AbstractFirebaseLogin
//
//  Created by Christopher Olsen on 2/14/18.
//  Copyright © 2018 Christopher Olsen. All rights reserved.
//

import Foundation

public struct User {
    public let uid: String
    public var email: String?
    public var creationDate: Date?
    public var lastSignInDate: Date?
}
