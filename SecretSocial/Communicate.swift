//
//  Communicate.swift
//  SecretSocial
//
//  Created by Andrei Homentcovschi on 1/28/19.
//  Copyright © 2019 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit

//let baseURL = "http://127.0.0.1:8000"
//let baseURL = "http://192.168.0.127:8000"
//let baseURL = "http://192.168.0.101:8000"
let baseURL = "http://172.20.10.2:8000"

func sendKeyMessage(toUser:String, channelId:Int16, isResponse:Bool, completion: @escaping (Bool) -> ())
{
    let username = getUserUsername()
    
    // get the AES key
    let key = getAESKey(channelId:channelId)
    let keydata = key.data(using: String.Encoding.utf8)!
    
    let URLForRequest = URL(string: baseURL + "/manual_user/GetManualUserPublicKey")!
    var request = URLRequest(url: URLForRequest)
    request.httpMethod = "POST"
    let postString = "username=\(toUser)"
    request.httpBody = postString.data(using: .utf8)
    
    let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
        guard let data = data else { return }
        let pubKeyString = String(data: data, encoding: .utf8);
        let toUserPublicKey = try! PEM.PublicKey.toDER(pubKeyString!)
        
        let encrypted = try? CC.RSA.encrypt(keydata, derKey: toUserPublicKey, tag: Data(), padding: .pkcs1, digest: .none)
        let encryptedString = encrypted?.base64EncodedString()
        
        // send the key to the toUser
        let URLForRequest = URL(string: baseURL + "/manual_user/SendUserEncryptedMessage")!
        var request = URLRequest(url: URLForRequest)
        request.httpMethod = "POST"
        let postString = "toUser=\(toUser)&fromUser=\(username)&message=\(encryptedString!)&channelId=\(channelId)"
        request.httpBody = postString.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data else { return }
            let responseString = String(data: data, encoding: .utf8)
            if responseString == "Success"{
                completion(true)
                if isResponse == false && channelId == 0 {
                    addToRequestsSent(user:toUser)
                }
            }
            else{
                completion(false)
            }
        }
        task.resume()
        
    }
    task.resume()
}


func deleteMessage(fromUser:String, channelId:Int16)
{
    // toUser is this client
    let toUser = getUserUsername()
    
    // fromUser is from the sender of the message
    let URLForRequest = URL(string: baseURL + "/manual_user/DeleteUserEncryptedMessages")!
    var request = URLRequest(url: URLForRequest)
    request.httpMethod = "POST"
    let postString = "toUser=\(toUser)&fromUser=\(fromUser)&channelId=\(channelId)"
    request.httpBody = postString.data(using: .utf8)
    
    let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
        guard let data = data else { return }
    }
    task.resume()
}
