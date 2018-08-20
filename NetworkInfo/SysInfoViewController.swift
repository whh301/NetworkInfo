//
//  SysInfoViewController.swift
//  NetworkInfo
//
//  Created by Wu Xiaohua on 8/20/18.
//  Copyright © 2018 Wu Xiaohua. All rights reserved.
//

import UIKit

class SysInfoViewController: UIViewController {

    // MARK: Label variants
    @IBOutlet weak var ipAddr: UILabel!
    @IBOutlet weak var gateWay: UILabel!
    @IBOutlet weak var dnsServer: UILabel!
    @IBOutlet weak var mobNw: UILabel!
    @IBOutlet weak var wifiSsid: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupSysInfo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Set the system information
    private func setupSysInfo() {
        var allIfs = NetInterface.allInterfaces()
        for i in 0..<allIfs.count {
            if allIfs[i].family == NetInterface.Family.ipv4 && !allIfs[i].isLoopback {
                ipAddr.text = allIfs[i].address
                gateWay.text = allIfs[i].gateWay
                dnsServer.text = allIfs[i].dnsserver
            }
        }
        
        mobNw.text = NetInterface.getRadioNetworkType()
        wifiSsid.text = NetInterface.getWiFiSsid()
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
