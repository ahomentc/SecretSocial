//
//  StringRegex.swift
//  SecretSocial
//
//  Created by Andrei Homentcovschi on 1/11/19.
//  Copyright © 2019 Andrei Homentcovschi. All rights reserved.
//

import Foundation


extension String
{
    func getUrlFromString() -> [String]
    {
//        if let regex = try? NSRegularExpression(pattern: "http://127.0.0.1:8000/encrypted_data_storage/[0-9]+/", options: .caseInsensitive)
//        let pattern = baseURL + "/encrypted_data_storage/[0-9]+/?"
        let pattern = "seed.com/p/[0-9]+"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        {
            let string = self as NSString
            let match = regex.matches(in: self, options: [], range: NSRange(location: 0, length: string.length)).map {
                string.substring(with: $0.range).replacingOccurrences(of: "#", with: "").lowercased()
            }
            return match
        }
        return []
    }
    
    func getUsername() -> [String]
    {
        // let pattern = "Posted with seed by [a-zA-Z0-9_-]+"
        let pattern = "Try the Seed app to show [a-zA-Z0-9_-]+'s post"
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        {
            let string = self as NSString
            return regex.matches(in: self, options: [], range: NSRange(location: 0, length: string.length)).map {
                string.substring(with: $0.range).replacingOccurrences(of: "#", with: "").lowercased()
            }
        }
        return []
    }
}
