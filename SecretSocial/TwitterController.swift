//
//  TwitterController.swift
//  SecretSocial
//
//  Created by Andrei Homentcovschi on 1/5/19.
//  Copyright © 2019 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import WebKit
import CoreData
import SwiftyRSA

class TwitterController: UIViewController, WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate {
    
    var webView: WKWebView!
    var url: String!
    var aes_key: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let myURL = URL(string:"https://mobile.twitter.com/login")
        let myRequest = URLRequest(url: myURL!)
        
        let webConfiguration = WKWebViewConfiguration()
        if #available(iOS 10.0, *){
            webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        }
        webConfiguration.allowsInlineMediaPlayback = true
        
        // enable communication between swift and javascript
        let contentController = WKUserContentController()
        let userScript = WKUserScript(
            source: "mobileHeader()",
            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(userScript)
        contentController.add(
            self,
            name: "callbackHandler"
        )
        contentController.add(
            self,
            name: "createNewTweet"
        )
        contentController.add(
            self,
            name: "requestFriendMessage"
        )
        webConfiguration.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        view = webView
        
        webView.load(myRequest)
        
        // set status bar color
        let statusBarView = UIView(frame: UIApplication.shared.statusBarFrame)
        let statusBarColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
        statusBarView.backgroundColor = statusBarColor
        view.addSubview(statusBarView)
        
        self.navigationItem.setHidesBackButton(true, animated: false)
    }
    
    // once webview loads...
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // replace engrypted text
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(TwitterController.getURLS), userInfo: nil, repeats: true)
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(TwitterController.listenForCreateTweet), userInfo: nil, repeats: true)
    }
    
    // listen for when the user clicks the tweet button
    // send to swift the content of the tweet
    @objc func listenForCreateTweet() {
        let jsString =
        """
        var textAreas = document.getElementsByTagName("textarea");

        Array.from(items).forEach(function(item, i) {
            if (item.innerHTML.indexOf("Tweet") != -1) {
                item.addEventListener("click", function(event){
                    // if(!textAreas[0].value.includes("encrypted_data_storage")){
                    if(!textAreas[0].value.includes("Seed app to show")){
                        // send message to swift
                        try {
                            webkit.messageHandlers.createNewTweet.postMessage(textAreas[0].innerHTML);
                        }
                        catch(err) {
                            console.log('The native context does not exist yet');
                        }
                        event.stopImmediatePropagation();
                    }
                });
            }
        });
        """
        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }
    
    
    // scan the page to get all the urls of encrypted posts and send message of them to swift
    @objc func getURLS() {
        let jsString =
        """
        var items = document.getElementsByTagName("span");
        Array.from(items).forEach(function(item, i) {
            // if (item.innerHTML.indexOf("View this post with seed") != -1) {
            if (item.innerHTML.indexOf("Seed app to show") != -1) {
                var post = item.innerHTML.toString();

                // Do bfs to find url in children
                var url = '';
                var queue = [];
                var c = item.parentNode.children;
                for (var i = 0; i < c.length; i++) {
                    queue.push(c[i]);
                }
                while(queue.length > 0){
                    var child = queue.shift();

                    if(child.innerHTML.indexOf("seed.com/p") != -1) {
                        url = child.innerHTML;
                        break;
                    }
                    if ( url != ''){
                        break;
                    }
                    var new_children = child.children;
                    for (var i = 0; i < new_children.length; i++) {
                        queue.push(new_children[i]);
                    }
                }

                // send message to swift through "callbackHandler" (can change callbackHandler to anything)
                try {
                    if(url != ''){
                        webkit.messageHandlers.callbackHandler.postMessage(post + url);
                    }
                }
                catch(err) {
                    console.log('The native context does not exist yet');
                }
            }
            if (item.innerHTML.indexOf("#OwnYourPosts") != -1) {
                item.innerHTML = "";
            }
        });

        """
        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }
    
    // recieve messages from javascript
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        // get messages with post content
        if message.name == "callbackHandler" {
            // data is the raw content of the post
            if let data = message.body as? String
            {
                // get the url from the post
                let url = data.getUrlFromString()
                let original_url = url[0]

                // get username from the post
//                let username = data.getUsername()[0].replacingOccurrences(of: "posted with seed by ", with: "")
                var username = data.getUsername()[0]
                username = username.replacingOccurrences(of: "'s post", with: "")
                username = username.replacingOccurrences(of: "Try the Seed app to show ", with: "")
                username = username.replacingOccurrences(of: "try the seed app to show ", with: "")

                if(url.count > 0){
                    var data_url = url[0]
                    // replace seed.com/p/ with baseURL + "/encrypted_data_storage/
                    data_url = data_url.replacingOccurrences(of: "seed.com/p/", with: baseURL + "/encrypted_data_storage/")
                    
                    // get encrypted data for the url
                    getEncryptedData(url: data_url + "/",original_url:original_url,username:username)
                }
            }
        }
        
        // get messages with post content
        if message.name == "createNewTweet" {
            if let data = message.body as? String
            {
                // **** TODO ****
                // alert to ask user which channelID
                encryptAndStore(tweetContent: data)
            }
        }
        
        if message.name == "requestFriendMessage" {
            if let usernameToAdd = message.body as? String
            {
                sendKey(toUser: usernameToAdd)
            }
        }
    }
    
    // post to get encrypted content from a url
    func getEncryptedData(url:String,original_url:String,username:String)
    {
        // the url
        let URLForRequest = URL(string: url)!
        var request = URLRequest(url: URLForRequest)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        // the parameters
        //        let postString = "id=13&name=Jack"
        let postString = ""
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
            }
            
            // get the encrypted message
            let responseString = String(data: data, encoding: .utf8)
            self.replaceWithDecrypted(url: url,original_url:original_url,encrypted_data: responseString!, username:username,channelId:0)
            
        }
        task.resume()
    }
    
    @objc func replaceWithDecrypted(url:String,original_url:String,encrypted_data:String, username:String, channelId:Int16) {
        // 1. if username same as user username check his keys
        // 2. elif username in friends then get username
        // 3. // ELSE IF FRIEND BUT DON'T HAVE CHANNEL ID
        // 4. elif username in FriendsRequestedByUser delete the post (don't show)
        // 5. else add the addUser button
        
        var aeskey = ""
        // get username of client
        let myUsername = getUserUsername()
        if username == myUsername || userInFriends(username: username){
            if username == myUsername{ // if username is client
                aeskey = getAESKey(channelId: channelId)
            }
            else{ // if username is friend
                aeskey = getFriendsKey(username:username, channelId:channelId)
            }
            let AES = CryptoJS.AES()
            let decrypted_data = AES.decrypt(encrypted_data, password: aeskey)

            let jsString =
                String(format:"""
                    var items = document.getElementsByTagName("span");
                    Array.from(items).forEach(function(item, i) {
                        var post = null;
                        if (item.innerHTML.indexOf('\(original_url)') != -1) {
                            // remove the original url
                            item.innerHTML = ''
                    
                            // get the non url part of post
                            var parent = item
                            while(parent != null){
                                // look through children of parent
                                var c = parent.children;
                                for (var i = 0; i < c.length; i++) {
                                    if(c[i].innerHTML.indexOf("Seed app to show") != -1){
                                        post = c[i];
                                        break;
                                    }
                                }
                    
                                if(parent.innerHTML.indexOf("Seed app to show") != -1){
                                    post = parent;
                                    break;
                                }
                                if(post != null){
                                    break;
                                }
                                parent = parent.parentNode;
                            }
                    
                            post.innerHTML = ''
                            var dot = document.createElement('span');
                            dot.style='height:7px; width:7px; margin-top: 6px; margin-right: 7px; float:left; background-color: #009933; border-radius: 100px; display: inline-block;';
                            var textlabel = document.createElement('label');
                            textlabel.innerHTML = '\(decrypted_data)';
                            post.appendChild(dot);
                            post.appendChild(textlabel);
                        }
                    });
                    """)
            
            // because evaluateJavaScript has to be called on main view
            DispatchQueue.main.async{
                self.webView.evaluateJavaScript(jsString, completionHandler: nil)
            }
        }
        else if userInFriendsRequestedByUser(username: username){ // remove post entirely
            let jsString =
                String(format:"""
                    var items = document.getElementsByTagName("span");
                    Array.from(items).forEach(function(item, i) {
                        if (item.innerHTML.indexOf('\(original_url)') != -1) {
                            var post = null;
                            item.innerHTML = '';
                    
                            // get the non url part of post
                            var parent = item
                            while(parent != null){
                                // look through children of parent
                                var c = parent.children;
                                for (var i = 0; i < c.length; i++) {
                                    if(c[i].innerHTML.indexOf("Seed app to show") != -1){
                                        post = c[i];
                                        break;
                                    }
                                }
                    
                                if(parent.innerHTML.indexOf("Seed app to show") != -1){
                                    post = parent;
                                    break;
                                }
                                if(post != null){
                                    break;
                                }
                                parent = parent.parentNode;
                            }
                        post.parentNode.parentNode.parentNode.parentNode.parentNode.parentNode.parentNode.removeChild(post.parentNode.parentNode.parentNode.parentNode.parentNode.parentNode);
                        }
                    });
                    """)
            
            // because evaluateJavaScript has to be called on main view
            DispatchQueue.main.async{
                self.webView.evaluateJavaScript(jsString, completionHandler: nil)
            }
        }
        else{
            let jsString =
                String(format:"""
                    var items = document.getElementsByTagName("span");
                    Array.from(items).forEach(function(item, i) {
                        if (item.innerHTML.indexOf('\(original_url)') != -1) {
                    
                            // remove the original url
                            item.innerHTML = ''
                    
                            var post = null;
                            var parent = item
                            while(parent != null){
                                // look through children of parent
                                var c = parent.children;
                                for (var i = 0; i < c.length; i++) {
                                    if(c[i].innerHTML.indexOf("Seed app to show") != -1){
                                        post = c[i];
                                        break;
                                    }
                                }
                    
                                if(parent.innerHTML.indexOf("Seed app to show") != -1){
                                    post = parent;
                                    break;
                                }
                                if(post != null){
                                    break;
                                }
                                parent = parent.parentNode;
                            }
                    
                            alert('\(username)')
                            post.innerHTML = 'Add \(username) as a friend to view post <br/>';
                            var button = document.createElement("button");
                            button.innerHTML = "Add Friend";
                            button.style = "background-color:#009933; border-color:#-009933; border-radius: 100px; color:white; font-size: 14px; font-weight: bold; text-align: center; padding-left: 20px; padding-right: 20px;padding-top: 5px; padding-bottom: 5px; margin-top: 20px; margin-bottom: 15px;"
                            post.appendChild(button);
                            button.addEventListener("click", function(event){
                            // send message to swift through "callbackHandler" (can change callbackHandler to anything)
                            try {
                                webkit.messageHandlers.requestFriendMessage.postMessage('\(username)');
                            }
                            catch(err) {}
                            });
                        }
                    });
                    """)
            
            // because evaluateJavaScript has to be called on main view
            DispatchQueue.main.async{
                self.webView.evaluateJavaScript(jsString, completionHandler: nil)
            }
        }
        // ELSE IF FRIEND BUT DON'T HAVE CHANNEL ID
        
    }
    
    var encryptedDataSent = false;
    // encypt data and send a POST to store it in database
    func encryptAndStore(tweetContent:String)
    {
        // get the AES key
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserKeys")
        request.returnsObjectsAsFaults = false
        
        if(!encryptedDataSent)
        {
            do
            {
                let result = try context.fetch(request)
                if result.count == 0
                {
                    print("no AES key to encrypt")
                }
                else
                {
                    for data in result as! [NSManagedObject]
                    {
                        let id = data.value(forKey: "channelId") as! Int
                        // if the general group (friends)
                        if(id == 0)
                        {
                            let key = data.value(forKey: "aesKey") as! String
                            // encrypt the data with the key with CryptoJs
                            // cryptoJs isn't very good and im not using any padding for simplicity now
                            // later on switch to a better tool without javascript and do better encryption
                            let AES = CryptoJS.AES()
                            let encrypted = String(AES.encrypt(tweetContent, password: key)).trimmingCharacters(in: .whitespaces)
                            
                            // send the encrypted content to the server
                            // the url
//                            let URLForRequest = URL(string: "http://127.0.0.1:8000/encrypted_data_storage/StoreEncryptedData")!
                            let URLForRequest = URL(string: baseURL + "/encrypted_data_storage/StoreEncryptedData")!
                            var request = URLRequest(url: URLForRequest)
                            request.httpMethod = "POST"
                            let postString = "data=\(encrypted)"
                            request.httpBody = postString.data(using: .utf8)
                            
                            let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
                                guard let data = data else { return }
//                                let url = baseURL + "/encrypted_data_storage/" + String(data: data, encoding: .utf8)! + "/"
                                let url = "seed.com/p/" + String(data: data, encoding: .utf8)! + "/"
                                self.replaceTweetSubmission(url: url)
                            }
                            
                            task.resume()
                        }
                    }
                }
            }
            catch
            {
                print("Failed")
            }
        }
    }
    
    @objc func replaceTweetSubmission(url:String) {
        
        // first get the username
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserInfo")
        request.returnsObjectsAsFaults = false
        do
        {
            let result = try context.fetch(request)
            if result.count > 0
            {
                for data in result as! [NSManagedObject]
                {
                    let username = data.value(forKey: "username") as! String
                    
                    // replace the form content with message and url
                    let jsString =
                        String(format:"""
                            var textAreas = document.getElementsByTagName("textarea");
                            textAreas[0].focus();
                            textAreas[0].value = "";
                            
                            // var te = document.createEvent('TextEvent');
                            // te.initTextEvent('textInput', true, true, window, 'View this post with seed: ');
                            // textAreas[0].dispatchEvent(te);
                            
                            var te = document.createEvent('TextEvent');
                            te.initTextEvent('textInput', true, true, window, "Try the Seed app to show \(username)'s post: ");
                            textAreas[0].dispatchEvent(te);
                            
                            var te = document.createEvent('TextEvent');
                            te.initTextEvent('textInput', true, true, window, '\(url)');
                            textAreas[0].dispatchEvent(te);
                            
                            // var te = document.createEvent('TextEvent');
                            // te.initTextEvent('textInput', true, true, window, '     Posted with seed by \(username)');
                            // textAreas[0].dispatchEvent(te);
                            
                            Array.from(items).forEach(function(item, i) {
                            if (item.innerHTML.indexOf("Tweet") != -1) {
                            item.click();
                            }
                            });
                            """)
                    // because evaluateJavaScript has to be called on main view
                    DispatchQueue.main.async{
                        self.webView.evaluateJavaScript(jsString, completionHandler: nil)
                        self.encryptedDataSent = false
                    }
                }
            }
        }
        catch
        {
            print("Failed")
        }
    }
    
    // ** need to go over this **
    // what calls this and why is this calling replaceTweetSubmission
    // also add user key was sent to, to the FriendsRequestedByUser
    // also only send message if for the channelId the message wasn't already sent
    func sendKey(toUser:String)
    {
        // first get the public key of the user
//        let URLForRequest = URL(string: "http://127.0.0.1:8000/manual_user/GetManualUserPublicKey")!
        let URLForRequest = URL(string: baseURL + "/manual_user/GetManualUserPublicKey")!
        var request = URLRequest(url: URLForRequest)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        // the parameters
        let postString = "username=\(toUser)"
        request.httpBody = postString.data(using: .utf8)
        encryptedDataSent = true
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error")
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
            }

            // get the reponse message: the url
            let pubKeyString = String(data: data, encoding: .utf8);
            let toUserPublicKey = try! PEM.PublicKey.toDER(pubKeyString!)
            
            // get the aes key to send
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserKeys")
            request.returnsObjectsAsFaults = false
            
            do {
                let result = try context.fetch(request)
                if result.count > 0
                {
                    for data in result as! [NSManagedObject]
                    {
                        let id = data.value(forKey: "channelId") as! Int
                        // if the aes key has channelId 0 (all friends)
                        if(id == 0)
                        {
                            let key = data.value(forKey: "aesKey") as! String
                            let keydata =  key.data(using: String.Encoding.utf8)!
                           
                            // encrypt with the public key gotten above
                            let encrypted = try? CC.RSA.encrypt(keydata, derKey: toUserPublicKey, tag: Data(), padding: .pkcs1, digest: .none)
                            let encryptedString = encrypted?.base64EncodedString()
                            
                            // send the encrypted content to the server
                            // the url
//                            let URLForRequest = URL(string: "http://127.0.0.1:8000/manual_user/SendUserEncryptedMessage")!
                            let URLForRequest = URL(string: baseURL + "/manual_user/SendUserEncryptedMessage")!
                            var request = URLRequest(url: URLForRequest)
                            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                            request.httpMethod = "POST"
                            
                            let userUsername = self.getUserUsername()
                            if (userUsername != "")
                            {
                                // the parameters
                                let postString = "toUser=\(toUser)&fromUser=\(userUsername)&message=\(encryptedString!)&channelId=0"
                                request.httpBody = postString.data(using: .utf8)
                                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                                    guard let data = data, error == nil else {                                                 // check for fundamental networking error
                                        print("error")
                                        return
                                    }
                                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                                        print("statusCode should be 200, but is \(httpStatus.statusCode)")
                                    }
                                    // get the reponse message: the url
                                    let responseString = String(data: data, encoding: .utf8)
                                    addToRequestsSent(user: toUser)
                                    
                                    // replace the javascript to say request sent
                                    
                                }
                                task.resume()
                            }
                        }
                    }
                }
            }
            catch
            {
                print("Failed")
            }
        }
        task.resume()
    }
    
    // Enable javascript alerts
    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let title = NSLocalizedString("OK", comment: "OK Button")
        let ok = UIAlertAction(title: title, style: .default) { (action: UIAlertAction) -> Void in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(ok)
        present(alert, animated: true)
        completionHandler()
    }
    
    func getUserUsername() -> String
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserInfo")
        request.returnsObjectsAsFaults = false
        do{
            let result = try context.fetch(request)
            if result.count > 0{
                for data in result as! [NSManagedObject]{
                    return data.value(forKey: "username") as! String
                }
            }
        }
        catch{print("Failed")}
        return "";
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
