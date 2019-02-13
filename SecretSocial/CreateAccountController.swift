//
//  CreateAccountController.swift
//  SecretSocial
//
//  Created by Andrei Homentcovschi on 1/11/19.
//  Copyright © 2019 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import CoreData

class CreateAccountController: UIViewController {
    
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: false)
    }
    
    @IBAction func createAccount(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // first check if username already exists
//        let URLForRequest = URL(string: "http://127.0.0.1:8000/manual_user/UsernameExists")!
        let URLForRequest = URL(string: baseURL + "/manual_user/UsernameExists")!
        var request = URLRequest(url: URLForRequest)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        // the parameters
        let postString = "username=\(username.text!)"
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error")
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
            }
            
            // get the server response
            let responseString = String(data: data, encoding: .utf8)
            if responseString! == "No" // username doesn't exist
            {
                // create public/private key
                let (privateKey, publicKey) = try! CC.RSA.generateKeyPair(2048)
                let privateKeyPEM = SwKeyConvert.PrivateKey.derToPKCS1PEM(privateKey)
                let publicKeyPEM = SwKeyConvert.PublicKey.derToPKCS8PEM(publicKey)
                
                // add the public/private key to entity
                let UserInfoEntity = NSEntityDescription.entity(forEntityName: "UserInfo", in: context)
                let newUserInfo = NSManagedObject(entity: UserInfoEntity!, insertInto: context)
                newUserInfo.setValue(self.name.text!, forKey: "name")
                newUserInfo.setValue(self.username.text!, forKey: "username")
                newUserInfo.setValue(self.password.text!, forKey: "password")
                newUserInfo.setValue(publicKeyPEM, forKey: "publicKey")
                newUserInfo.setValue(privateKeyPEM, forKey: "privateKey")
                
                // request to create the account in the server
//                let URLForRequest = URL(string: "http://127.0.0.1:8000/manual_user/CreateManualUser")!
                let URLForRequest = URL(string: baseURL + "/manual_user/CreateManualUser")!
                
                var request = URLRequest(url: URLForRequest)
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpMethod = "POST"
                
                // the request parameters
                let postString = "username=\(self.username.text!)&public_key=\(publicKeyPEM)"
                request.httpBody = postString.data(using: .utf8)
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let data = data, error == nil else {                                                 // check for fundamental networking error
                        print("error")
                        return
                    }
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                        print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    }
                    
                    // get the server response
                    let responseString = String(data: data, encoding: .utf8)
                    if responseString! == "Success" // if sucessfully created account
                    {
                        // create AES key
                        let number1 = Float.random(in: 0 ... 1000000000000000000000000000)
                        let numAsString = String(number1)
                        let AESKey = numAsString.hmac(key: numAsString)
                        print(AESKey)
                        
                        let UserKeysEntity = NSEntityDescription.entity(forEntityName: "UserKeys", in: context)
                        let newKey = NSManagedObject(entity: UserKeysEntity!, insertInto: context)
                        newKey.setValue(AESKey, forKey: "aesKey")
                        newKey.setValue(0, forKey: "channelId")
                        newKey.setValue("All Friends", forKey: "channelName")
                        
                        do {
                            try context.save()
                        } catch {
                            print("Failed saving")
                        }

                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "backToAccountHome", sender: nil)
                        }
                    }
                }
                task.resume()
            }
        }
        task.resume()

    }
    
}
