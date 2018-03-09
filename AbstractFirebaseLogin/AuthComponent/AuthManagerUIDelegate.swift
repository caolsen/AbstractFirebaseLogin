//
//  AuthManagerUIDelegate.swift
//  AbstractFirebaseLogin
//
//  Created by Christopher Olsen on 2/27/18.
//  Copyright © 2018 Christopher Olsen. All rights reserved.
//
//  This is simply a wrapper around the GIDSignInUIDelegate to better isolate and abstract the library.
//

import Foundation
import GoogleSignIn

public protocol AuthManagerUIDelegate: class, GIDSignInUIDelegate {}
