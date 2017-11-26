//
//  HomeViewController.swift
//  facebook-login
//
//  Created by Javier Diaz on 17/11/2017.
//  Copyright © 2017 jvrmed. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class HomeViewController: UIViewController {
    
    enum LoginResult {
        case success
        case cancelled
        case error
        case none
    }
    
    var loginResult: LoginResult = .none

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup login button
        let myLoginButton = UIButton(type: .custom)
        myLoginButton.backgroundColor = UIColor.darkGray
        myLoginButton.frame = CGRect(x: 0, y: 0, width: 180, height: 40)
        myLoginButton.center = view.center
        myLoginButton.setTitle("My Login Button", for: .normal)
        
        // Handle clicks on the button
        myLoginButton.addTarget(self, action: #selector(loginButtonClicked), for: .touchUpInside)
        
        // Add the button to the view
        view.addSubview(myLoginButton)
    }

    // Once the button is clicked, show the login dialog
    @objc func loginButtonClicked() {
        
        // Get login manager from Service
        let loginManager = FacebookService.sharedInstance   
        
        loginManager.logIn(withReadPermissions: ["public_profile"], from: self) { (result, error) in
            if let result = result {
                if let _ = error {
                    self.loginResult = .error
                } else if result.isCancelled {
                    self.loginResult = .cancelled
                } else if let _ = result.token {
                    self.loginResult = .success
                }
            } else {
                self.loginResult = .error
            }
        }
    }
}
