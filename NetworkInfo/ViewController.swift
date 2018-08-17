//
//  ViewController.swift
//  NetworkInfo
//
//  Created by Wu Xiaohua on 8/16/18.
//  Copyright © 2018 Wu Xiaohua. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    // For labels:
    @IBOutlet weak var lblIpAddr: UILabel!
    @IBOutlet weak var lblGateWay: UILabel!
    @IBOutlet weak var lblDnsServer: UILabel!
    @IBOutlet weak var lblNwType: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setupNwInfo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func setupNwInfo() {
        var allIfs = NetInterface.allInterfaces()
        for i in 0..<allIfs.count {
            if !allIfs[i].isLoopback && allIfs[i].family == NetInterface.Family.ipv4 {
                lblIpAddr.text = allIfs[i].address
                lblDnsServer.text = allIfs[i].dnsserver
                break
            }
        }
    }
}

