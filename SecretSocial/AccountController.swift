//
//  AccountController.swift
//  SecretSocial
//
//  Created by Andrei Homentcovschi on 1/11/19.
//  Copyright © 2019 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import CoreData

class AccountController: UIViewController
{
    
    @IBOutlet weak var welcome: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        addNewKeysFromMessages()
        
    }
    
    // add key if sender is in FriendsRequestedByUser  (do send(isReponse=false) )
    // or add key if sender is already a friend

    func addNewKeysFromMessages(){
        let username = getUserUsername()
        
        let URLForRequest = URL(string: baseURL + "/manual_user/GetUserEncryptedMessages")!
        var request = URLRequest(url: URLForRequest)
        request.httpMethod = "POST"
        let postString = "username=\(username)"
        request.httpBody = postString.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data else { return }
            let responseString = String(data: data, encoding: .utf8)
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: responseString!.data(using: String.Encoding.utf8)!, options:JSONSerialization.ReadingOptions(rawValue: 0))
                guard let dictionary = jsonObject as? Dictionary<String, Any> else { return }
                for (usr,usrkeyString) in dictionary {
                    // usrKeyArr[0] = channelId and usrKeyArr[1] = key
                    let usrKeyArr = (usrkeyString as! String).components(separatedBy: "_")
                    // if sender is a friend or user has sent a request
                    if userInFriends(username: usr){
                        let keyCreated = createForeignKey(username:usr, key:usrKeyArr[1], channelId:Int16(usrKeyArr[0])!)
                        if keyCreated {
                            // if the key was sucessfully created, delete the message
                            deleteMessage(fromUser:usr, channelId:Int16(usrKeyArr[0])!)
                        }
                    }
                    else if userInFriendsRequestedByUser(username: usr){
                        let privateKeyString = getUserPrivateKey()
                        let toUserPrivateKey = try! PEM.PrivateKey.toDER(privateKeyString)
                        
                        let encrypted_string = usrKeyArr[1].data(using: String.Encoding.utf8)!
                        let encrypted_data = Data(base64Encoded: encrypted_string)!
                        let decrypted = try? CC.RSA.decrypt(encrypted_data, derKey: toUserPrivateKey, tag: Data(), padding: .pkcs1, digest: .none)
                        
                        let decryptedKey = String(data: decrypted!.0, encoding: String.Encoding.utf8) as String!
                        
                        createFriend(username: usr)
                        let keyCreated = createForeignKey(username: usr, key:decryptedKey!, channelId:0)
                        
                        // send delete signal to delete the message
                        if keyCreated{ // if the key was sucessfully created delete the message
                            deleteMessage(fromUser:usr, channelId:0)
                            removeFromFriendsRequested(username: usr)
                        }
                    }
                }
            }
            catch let error as NSError {
                print("Found an error - \(error)")
            }
            
        }
        
        task.resume()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

}
