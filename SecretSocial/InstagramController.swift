//
//  InstagramController.swift
//  SecretSocial
//
//  Created by Andrei Homentcovschi on 1/5/19.
//  Copyright © 2019 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import WebKit

class InstagramController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    
    var webView: WKWebView!
    var url: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myURL = URL(string:"https://instagram.com/accounts/login")
        let myRequest = URLRequest(url: myURL!)
        
        let webConfiguration = WKWebViewConfiguration()
        if #available(iOS 10.0, *){
            webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        }
        webConfiguration.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        view = webView
        
        webView.load(myRequest)
        
        self.navigationItem.setHidesBackButton(true, animated: false)

        // Do any additional setup after loading the view.
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        fixHeader(into: webView)
    }
    
    func fixHeader(into webView: WKWebView) {
        let cssString = "header {padding-top: 40px;padding-top: constant(safe-area-inset-top);padding-top: env(safe-area-inset-top);} body{padding-top: 60px}"
        let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
        webView.evaluateJavaScript(jsString, completionHandler: nil)
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
