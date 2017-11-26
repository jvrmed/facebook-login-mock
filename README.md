# Motivation

Recently I've been diving more and more into testing and a lot of questions have popped up, specially regarding how to test 
third party services. Unless you want to reinvent the wheel all the time, it's normal (and even expected) that we all use at some point in our
code some library or framework that was not developed by ourselves. When it comes to that, I started to think that testing
the parts of my code that were related to those components was really complicated. However, recently I discovered one approach
that it's quite straightforward and allows mocking of almost everything, so let's jump into it! If you want, you can find all
the code used in this post [here](https://github.com/jvrmed/facebook-login-mock).

# How it works

We all know how flexible and powerful [protocols](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Protocols.html) 
can be in _Swift_ and it's very common to use them when implementing delegates for example. In fact, our dearest `UITableViewDataSource`
and `UITableViewDelegate` are nothing more than that, protocols waiting to be implemented. However, when considering third-party
frameworks such as Facebook's, the implementation is already done and we can't change it much. Luckily the approach to mock
it is quite simple. For this example, I will use Facebook's login flow to show how we can test different scenarios
such as success, cancel and failure and be sure that our app behaves as it should depending on the service's response.

## 1. Find your interface

If you go to [Facebook's Swift SDK - Getting Started](https://developers.facebook.com/docs/swift/login) you will find an example
on how to create a custom login button that uses their `LoginManager` to perform a simple login. The flow is quite simple,
given some permissions you can either login successfully, cancel the login flow or get an error. I did some changes to their
example to set up different values according to the service response:

```swift
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
                if let _ = result.token {
                    self.loginResult = .success
                } else if result.isCancelled {
                    self.loginResult = .cancelled
                } else if let _ = error {
                    self.loginResult = .error
                }
            }
        }
    }
}
```
    
Considering our own app login flow, what we want to test here is what would happen in our app in every case of Facebook's
login flow: success, user cancel and failure. In other words, to be able to mock the result of the `loginManager.logIn` call.
So the first step is to know the exact interface of that method. To do that, we can use Xcode's autocomplete to generate it for us.

![Xcode autocomplete](https://github.com/jvrmed/facebook-login-mock/blob/master/images/autocomplete-preview.png)

Simply use your `loginManager` variable to see the available methods until your find the one you are interested in. After you
 select it, you should have something like this:
 
```swift
loginManager.logIn(
    withReadPermissions: [Any]!,
    from: UIViewController!,
    handler: FBSDKLoginManagerRequestTokenHandler!
)
```
    
But Javier, why you just not look at the Documentation instead of using Xcode to figure out the method signature? It's an excellent
question actually. Sometimes the documentation is enough to find how the interface should be. However, depending on how you
installed your framework, its possible that you can only access its headers and sometimes those headers are in Objective-C. 
In this case, if you open _FBSDKLoginManager.h_ you will find the following interface:

```objectivec
- (void)logInWithReadPermissions:(NSArray *)permissions
          fromViewController:(UIViewController *)fromViewController
                     handler:(FBSDKLoginManagerRequestTokenHandler)handler;
```
                         
Since we have optionals and some other important differences between Objective-C and Swift, its easier and quicker just to
grab the method signature straight from where we are using it instead of looking around in other dark and ugly places.

## 2. Create a protocol

Now that we have the exact interface that the method that we need to mock uses, we can create a protocol with it:

```swift
// Custom protocol matching signatures of methods you want to test
protocol FacebookProtocol {
    func logIn(
        withReadPermissions: [Any]!,
        from: UIViewController!,
        handler: FBSDKLoginManagerRequestTokenHandler!
    )
}
```

So far nothing special. What we are doing here is to create a protocol that, once is adopted by a class, it will implement
a method with the same interface that the `FBSDKLoginManager` uses.

## 3. Extend your third-party service

For me this is the magic part. By using _Swift_ extension we can extend (duh!) any kind of object or class with new methods or
variables. However, we can also use extensions to standardise interfaces. Since we can't directly modify some third-party frameworks
 we can just make them compliant with custom protocols that they already implement by themselves.
  
```swift
// Extend your third party service to comply with custom protocol
extension FBSDKLoginManager: FacebookProtocol {}
```
  
What we are doing here is telling our compiler that `FBSDKLoginManager` complies with `FacebookProtocol`, hence, it implements
all the methods that the protocol defines. In general, we make classes conform to a protocol to implement those interfaces,
as in the `UITableViewDataSource` case for example. However, in this case we know that `FBSDKLoginManager` already implements
the `logIn` method, even that we don't know how. 

But why do we need a _hood_ interface for our third-party service?

## 4. Replace third-party types

Once your protocol is in place its easier to abstract the services among your codebase. What we have to do is to create a single
entry point for the third-party service. In this case, instead of using `FBSDKLoginManager` variables every time we need to
perform some login related action, we will create our own service that will keep a single instance of `FBSDKLoginManager`.

```swift
class FacebookService {
    // Shared instance that conforms with protocol
    static var sharedInstance: FacebookProtocol = FBSDKLoginManager()
}
```

As you can see, the variable type is `FacebookProtocol` instead of `FBSDKLoginManager` but the default value is a `FBSDKLoginManager`
instance. This is possible because of our extension. Since `FBSDKLoginManager` conforms with `FacebookProtocol`, we can
set to our shared instance any class that conforms with that protocol. And now that we have a single instance for our service,
we can use it in our code instead of using the third-party constructor directly.

```swift
@objc func loginButtonClicked() {
    
    // Get login manager from Service
    let loginManager = FacebookService.sharedInstance   
    
    ...
    
}
```
    
## 5. Mock those services

Once we have our protocol in place and a single access point for the third-party service we can easily mock them by creating
new objects that comply with `FacebookProtocol` and replacing our `FacebookService.sharedInstance` with it. By doing this,
every part of our code that uses `FBSDKLoginManager` will call our mock instead and we will be able to check if our app handles
responses properly.

So first of all we create our mock. We will set it up with two variables, one for the expected result and one for possible errors.
Those variables are the ones we are going to use to check if the response handler is called properly. Also, we will implement
the `logIn` method to execute the handler with those variables. Don't forget to make your mock compliant to `FacebookProtocol`.


```swift
class FBSDKLoginManagerMock: FacebookProtocol {
    var result: FBSDKLoginManagerLoginResult?
    var error: NSError?
    
    func logIn(withReadPermissions: [Any]!, from: UIViewController!, handler: FBSDKLoginManagerRequestTokenHandler!) {
        handler(self.result, self.error)
    }
}
```
    
In our test case, we will create some extra variables too so we can store a reference to our mock, to our tested controller and
to a token that its required to create a `FBSDKLoginManagerResult`. In our `setUp` method we will initialise all those variables
and reset our controller's `loginResult` back to `.none` so we ensure the same start point for all tests.

```swift 
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
    
...
```
    
Last but not least, we create some tests to check if our controller handle the response properly and changes the value of
`loginResult` variable according to the response:

```swift
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
```
    
In these cases we are merely checking if the response was handled properly by using the `loginResult` variable. However, in
real life scenarios we would like to test if error alerts were displayed, if navigation happened property or, for example,
if the token that Facebook send us was stored properly.
  
# Conclusion

I think that testing our codebase is extremely important to ensure quality software. However, by personal experience I know
that testing can become a bottleneck during the development cycle if we don't know exactly what to test or even worst, if
we don't know how to test it.

With this article I hope to bring some light to those that have faced this challenge at some point and to give insights to
to those that want to develop better code. I am aware that there are different approaches to this problem but personally
this solution has come very handy to me when testing frameworks such as Facebook's, CoreLocation and AVFoundation so luckily
it will be useful for you too.
