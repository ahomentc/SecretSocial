//
//  FriendRequestTableViewController.swift
//  SecretSocial
//
//  Created by Andrei Homentcovschi on 1/28/19.
//  Copyright © 2019 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit

protocol FriendRequestDelegate: class {
    // delegate to be able to  reload the table from the TableViewCell
    func reloadTable(removed:String)
}

class FriendRequestTableViewController: UITableViewController, FriendRequestDelegate {
    
    private var requests: [(String,String)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadRequests()
    }
    
    private func loadRequests() {
        // first get username
        let username = getUserUsername()
        print(username)
        
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
                guard let dictionary = jsonObject as? Dictionary<String, Any> else {
                    print("Not a Dictionary")
                    // put in function
                    return
                }
                for (usr,usrkeyString) in dictionary {
                    let usrKeyArr = (usrkeyString as! String).components(separatedBy: "_")
                    if usrKeyArr[0] == "0" && userInFriendsRequestedByUser(username: usr) == false && userInFriends(username: usr) == false {
                        // add only channel 0 messages (friend) and do not add anyone already requested or already friends with
                        self.requests.append((usr,usrKeyArr[1]))
                    }
                }
                print(self.requests)
                self.tableView.reloadData()
            }
            catch let error as NSError {
                print("Found an error - \(error)")
            }
            
        }
        
        task.resume()
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requests.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "FriendRequestTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? FriendRequestTableViewCell  else {
            fatalError("The dequeued cell is not an instance of FriendRequestTableViewCell.")
        }
        cell.delegate = self

        let request = requests[indexPath.row]
        print(request)
        cell.username.text = request.0
        cell.encrypedKey.text = request.1

        return cell
    }
    
    func reloadTable(removed:String) {
        var indexToRemove = 0
        for (username,_) in requests{
            if username == removed{
                break
            }
            indexToRemove+=1
        }
        requests.remove(at: indexToRemove)
        
        self.tableView.reloadData()
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
}
