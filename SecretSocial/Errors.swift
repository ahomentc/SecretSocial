//
//  Errors.swift
//  SecretSocial
//
//  Created by Andrei Homentcovschi on 1/30/19.
//  Copyright © 2019 Andrei Homentcovschi. All rights reserved.
//

import Foundation

struct RuntimeError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    public var localizedDescription: String {
        return message
    }
}
