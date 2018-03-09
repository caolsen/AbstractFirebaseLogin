//
//  Result.swift
//  AbstractFirebaseLogin
//
//  Created by Christopher Olsen on 3/7/18.
//  Copyright © 2018 Christopher Olsen. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case failure(Error)
}

extension Result {
    
    func resolve() throws -> T {
        switch self {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
    
    init(throwingExpr: () throws -> T) {
        do {
            let value = try throwingExpr()
            self = .success(value)
        } catch {
            self = .failure(error)
        }
    }
}
