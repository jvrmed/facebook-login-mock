//
//  FacebookService.swift
//  facebook-login
//
//  Created by Javier Diaz on 20/11/2017.
//  Copyright © 2017 jvrmed. All rights reserved.
//

import UIKit
import FBSDKLoginKit

// Custom protocol matching signatures of methods you want to test
protocol FacebookProtocol {
    func logIn(
        withReadPermissions: [Any]!,
        from: UIViewController!,
        handler: FBSDKLoginManagerRequestTokenHandler!
    )
}

// Extend your third party service to comply with custom protocol
extension FBSDKLoginManager: FacebookProtocol {}


class FacebookService {
    // Shared instance that conforms with protocol
    static var sharedInstance: FacebookProtocol = FBSDKLoginManager()
}


