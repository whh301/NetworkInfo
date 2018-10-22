//
//  NetInfoViewController.swift
//  NetworkInfo
//
//  Created by xhwu on 8/17/18.
//  Copyright © 2018 Wu Xiaohua. All rights reserved.
//

import UIKit

class NetInfoViewController: UIViewController {

    @IBOutlet weak var leadingC: NSLayoutConstraint!
    @IBOutlet weak var trailingC: NSLayoutConstraint!
    
    @IBOutlet weak var ubeView: UIView!
    @IBOutlet weak var txtBleSend: UITextField!
    @IBOutlet weak var btnBleSend: UIButton!
    @IBOutlet weak var txtBleRcvd: UITextView!
    
    var isMenuIsVisible = false
    var firebase:FirebaseAuthentication!
    
    var adbSrv:AdbService!
    
    @IBAction func btnTapped(_ sender: Any) {
        if !isMenuIsVisible {
            leadingC.constant = 150
            trailingC.constant = -150
            
            isMenuIsVisible = true
        } else {
            leadingC.constant = 0
            trailingC.constant = 0
            
            isMenuIsVisible = false
        }
        
        // Animation
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }) { (animationComplete) in
            print("The animation is complete!")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        firebase = FirebaseAuthentication(method: FirebaseAuthentication.AUTH_FIREBASE)
        //if !firebase.isfirebaseSignedIn() {
        //    Log.d(tag: "Login", string: "EXIT")
        //} else {
        //    Log.d(tag: "Login", string: "Sign In Success, starting service!")
        //    MyFirebaseMessagingService.sendRegister()
        //}
        
        // AdbService thread
        adbSrv = AdbService(owner: self)
        adbSrv.start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleUpstreamData(data: String) {
        // Display the message to screen
        txtBleRcvd.text = txtBleRcvd.text + "\n <== " + data
    }

    @IBAction func btnSendTapped(_ sender: Any) {
        // Send the message
        if (adbSrv != nil && txtBleSend.text != nil) {
            adbSrv.sendMessage(data: txtBleSend.text!)
            
            txtBleRcvd.text = txtBleRcvd.text + "\n ==> " + txtBleSend.text!
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
