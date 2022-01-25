//
//  ViewController.swift
//  ios-demo
//
//  Created by fql on 2022/1/4.
//

import OAuthSwift
import JWTDecode
#if os(iOS)
import UIKit
import SafariServices
import WebKit
import Alamofire

#elseif os(OSX)
import AppKit
#endif

class ViewController: UIViewController {

    var oauthswift: OAuth2Swift?
    var userDafaluts: UserDefaults?
    public typealias Queue = DispatchQueue
    @IBOutlet weak var button: UIButton!

    
    @IBOutlet weak var appIdLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var logStateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let oauthswift = OAuth2Swift(
            consumerKey:    "YjBiYzNmZDFiMDI4NDM4ZmI0N2JmMmQ4MjJkMTU1YTI",
            consumerSecret: "r2QhCj3FyfHx8ebAaYUg1ATTIpBDnEQn",
            authorizeUrl:   "https://rc42jr.portal.tencentciam.com/oauth2/authorize",
            accessTokenUrl: "https://rc42jr.portal.tencentciam.com/oauth2/token",
            responseType:   "code",
            contentType:    "multipart/form-data"
        )
        self.oauthswift = oauthswift
        
        self.userDafaluts = UserDefaults.standard
        let task = DispatchWorkItem {
            while(true){
                let expireTime = self.userDafaluts?.object(forKey: "expireTime")
                print("expireTime is \(expireTime)")
                if(expireTime != nil){
                    DispatchQueue.main.async {
                        if(Date() < expireTime as! Date){
                            let phone = self.userDafaluts?.string(forKey: "phone")
                            let appId = self.userDafaluts?.string(forKey: "appId")
                            self.logStateLabel.text = "已登录"
                            if(phone != nil){
                                self.phoneNumberLabel.text = "电话号码：    "+phone!
                            }
                            if(appId != nil){
                                self.appIdLabel.text = "appId: "+appId!
                            }
                        }else{
                            self.logStateLabel.text = "未登录"
                            self.appIdLabel.text = ""
                            self.phoneNumberLabel.text = ""
                        }
                    }
                }
                sleep(1)
            }
        }
        
        let globalQueue = DispatchQueue.global()
        globalQueue.async(execute: task)
    }
    
    
    

    
    @IBAction func loginClick(_ sender: Any) {
        
        
        
//        print("success is \(userDefaluts.bool(forKey: "Success"))")
//        //userDefaluts.set(false,forKey: "Success")
//        print("success is \(userDefaluts.bool(forKey: "Success"))")
        doOAuthCiam()
    }
    
    
    @IBAction func logoutClick(_ sender: Any) {
        let u =  "https://rc42jr.portal.tencentciam.com/logout?client_id=YjBiYzNmZDFiMDI4NDM4ZmI0N2JmMmQ4MjJkMTU1YTI&logout_redirect_uri=ciam://oauth-callback/Ciam"
        let url = "ciam://oauth-callback/Ciam"
        guard let url = URL(string: url) else { return }
        let webViewURLHandler = WebViewController.init()
        self.oauthswift?.authorizeURLHandler = webViewURLHandler
        print("authorizeURLHandler is \(self.oauthswift?.authorizeURLHandler)")
        self.oauthswift?.authorizeURLHandler.handle(URL(string: u)!)
        userDafaluts?.set(Date(), forKey: "expireTime")
//        guard let url = URL(string: Url) else { return }
//        if(UIApplication.shared.canOpenURL(url)){
//            UIApplication.shared.open(url){result in
//                if(result){
//                    print("result is \(result)")
//                    self.logStateLabel.text = "未登录"
//                    self.appIdLabel.text = ""
//                    self.phoneNumberLabel.text = ""
//                }
//            }
//        }
    }
    func doOAuthCiam(){
        
        let state = "state"
        let redirectURL = "ciam://oauth-callback/Ciam"
        let safariURLHandler = SafariURLHandler(viewController: self, oauthSwift: self.oauthswift!)
        let webViewURLHandler = WebViewController.init()
        self.oauthswift?.authorizeURLHandler = webViewURLHandler
        let _ = self.oauthswift?.authorize(
            withCallbackURL: URL(string: redirectURL)!, scope: "openid", state: state) {result in
            switch result {
            case .success(let (credential, _, parameters)):
                
                var date = credential.oauthTokenExpiresAt!
                self.userDafaluts?.set(date, forKey: "expireTime")
                do {
                    let id_token = parameters["id_token"]! as! String
                    self.logStateLabel.text = "已登陆"
                    let jwt = try decode(jwt: id_token)
                    let phoneNumber = jwt.body["phoneNumber"]! as! String
                    let appId = jwt.body["aud"]! as! String
                    self.phoneNumberLabel.text = "电话号码：    "+phoneNumber
                    self.appIdLabel.text = "appId: "+appId
                    self.userDafaluts?.set(appId, forKey: "appId")
                    self.userDafaluts?.set(phoneNumber, forKey: "phone")
                } catch let error as NSError {
                    print("error is \(error)")
                }
            case .failure(let error):
                print(error.localizedDescription, terminator: "")
            }
        }
    }
}
