//
//  FriendRequestTableViewCell.swift
//  SecretSocial
//
//  Created by Andrei Homentcovschi on 1/28/19.
//  Copyright © 2019 Andrei Homentcovschi. All rights reserved.
//

import UIKit

class FriendRequestTableViewCell: UITableViewCell {
    weak var delegate: FriendRequestDelegate?

    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var encrypedKey: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func accept(_ sender: Any) {
        // the table only shows channel 0 messages
        
        let friendsRequested = getFriendsRequestedByUser()
        if friendsRequested.contains(username.text!) == false {
            // sends a message with key in reponse, if sucessfuly sent, then callback to store recipient's key
            sendKeyMessage(toUser:username.text!, channelId:0, isResponse:true, completion: { (success) -> Void in
                // decrypt the encryptedKey
                let privateKeyString = getUserPrivateKey()
                let toUserPrivateKey = try! PEM.PrivateKey.toDER(privateKeyString)

                let encrypted_string = self.encrypedKey.text!.data(using: String.Encoding.utf8)!
                let encrypted_data = Data(base64Encoded: encrypted_string)!
                let decrypted = try? CC.RSA.decrypt(encrypted_data, derKey: toUserPrivateKey, tag: Data(), padding: .pkcs1, digest: .none)
                
                let decryptedKey = String(data: decrypted!.0, encoding: String.Encoding.utf8) as String!
                
                createFriend(username: self.username.text!)
                let keyCreated = createForeignKey(username: self.username.text!, key:decryptedKey!, channelId:0)
                
                // send delete signal to delete the message
                if keyCreated{ // if the key was sucessfully created delete the message
                    deleteMessage(fromUser:self.username.text!, channelId:0)
                    self.delegate?.reloadTable(removed: self.username.text!)
                }
            })
        }
    }
    
    @IBAction func deny(_ sender: Any) {
        deleteMessage(fromUser:self.username.text!, channelId:0)
        delegate?.reloadTable(removed: self.username.text!)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
