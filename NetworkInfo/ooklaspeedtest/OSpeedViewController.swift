//
//  OSpeedViewController.swift
//  NetworkInfo
//
//  Created by Wu Xiaohua on 8/23/18.
//  Copyright © 2018 Wu Xiaohua. All rights reserved.
//

import UIKit

class OSpeedViewController: UIViewController {

    @IBOutlet weak var btnAction: UIButton!
    @IBOutlet weak var txtTestId: UITextField!
    
    @IBOutlet weak var lblTestStatus: UILabel!
    @IBOutlet weak var lblServerName: UILabel!
    @IBOutlet weak var lblLatency: UILabel!
    
    @IBOutlet weak var lblDlSpeed: UILabel!
    @IBOutlet weak var lblUlSpeed: UILabel!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var txtLogInfo: UITextView!
    
    var isTestRunning:Bool = false
    var editHelper: OSpeedEditConfigHelper!
    var commandHelper: OSpeedCommandHelper!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        editHelper = OSpeedEditConfigHelper()
        commandHelper = OSpeedCommandHelper(activity: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnStartClicked(_ sender: Any) {
        if btnAction.isSelected {
            btnAction.isSelected = false;
            btnAction.titleLabel?.text = "Start"
            btnAction.titleLabel?.backgroundColor = UIColor.green
        } else {
            btnAction.isSelected = true
            btnAction.titleLabel?.text = "Stop"
            btnAction.titleLabel?.backgroundColor = UIColor.red
        }
        
        commandHelper.ToggleButtonClick()
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
