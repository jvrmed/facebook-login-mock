//
//  facebook_loginTests.swift
//  facebook-loginTests
//
//  Created by Javier Diaz on 17/11/2017.
//  Copyright © 2017 jvrmed. All rights reserved.
//

import XCTest
import FBSDKLoginKit
@testable import facebook_login

class FBSDKLoginManagerMock: FacebookProtocol {
    var result: FBSDKLoginManagerLoginResult?
    var error: NSError?
    
    func logIn(withReadPermissions: [Any]!, from: UIViewController!, handler: FBSDKLoginManagerRequestTokenHandler!) {
        handler(self.result, self.error)
    }
}

class FacebookLoginTests: XCTestCase {
    
    var loginManagerMock: FBSDKLoginManagerMock!
    var controller: HomeViewController!
    var token: FBSDKAccessToken!
    
    override func setUp() {
        super.setUp()
    
        loginManagerMock = FBSDKLoginManagerMock()
        controller = HomeViewController()
        token = FBSDKAccessToken(tokenString: "", permissions: [], declinedPermissions: [], appID: "", userID: "", expirationDate: Date(), refreshDate: Date())
        controller.loginResult = .none
        
        XCTAssertNotNil(controller.view)
    }
    
    func testLoginSuccessful() {
        let result = FBSDKLoginManagerLoginResult.init(token: token, isCancelled: false, grantedPermissions: Set(), declinedPermissions: Set())
        
        loginManagerMock.result = result
        FacebookService.sharedInstance = loginManagerMock
        
        XCTAssertEqual(controller.loginResult, .none)
        controller.loginButtonClicked()
        XCTAssertEqual(controller.loginResult, .success)
    }
    
    func testLoginCancelled() {
        let result = FBSDKLoginManagerLoginResult.init(token: nil, isCancelled: true, grantedPermissions: Set(), declinedPermissions: Set())
        
        loginManagerMock.result = result
        FacebookService.sharedInstance = loginManagerMock
        
        XCTAssertEqual(controller.loginResult, .none)
        controller.loginButtonClicked()
        XCTAssertEqual(controller.loginResult, .cancelled)
    }
    
    func testLoginError() {
        let result = FBSDKLoginManagerLoginResult.init(token: nil, isCancelled: false, grantedPermissions: nil, declinedPermissions: nil)
        let error = NSError(domain: "", code: 0, userInfo: nil)
        
        loginManagerMock.result = result
        loginManagerMock.error = error
        FacebookService.sharedInstance = loginManagerMock
        
        XCTAssertEqual(controller.loginResult, .none)
        controller.loginButtonClicked()
        XCTAssertEqual(controller.loginResult, .error)
    }
    
}
