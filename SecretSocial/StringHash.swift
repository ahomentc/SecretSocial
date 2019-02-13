//
//  StringHash.swift
//  SecretSocial
//
//  Created by Andrei Homentcovschi on 1/11/19.
//  Copyright © 2019 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import CommonCrypto

extension String {
    
    func hmac(key: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), key, key.count, self, self.count, &digest)
        let data = Data(bytes: digest)
        return data.map { String(format: "%02hhx", $0) }.joined()
    }
    
}
