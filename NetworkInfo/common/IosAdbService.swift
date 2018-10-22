//
//  IosAdbService.swift
//  NetworkInfo
//
//  Created by Wu Xiaohua on 8/20/18.
//  Copyright © 2018 Wu Xiaohua. All rights reserved.
//

import Foundation
import UIKit

class AdbService {
    let TAG:String = "AdbService"
    open static let LOCAL_DIR:String = NSHomeDirectory()
    open static let licenseFile:String = "license.dat"
    open static let CONFIG_FILE:String = "\(LOCAL_DIR)/ts_config.xml"
    open static let LTE_INFO_NAME:String = "mobile_info"
    open static let account:String = "/account.txt"
    open static let SPEED_SERVER_LIST:String = ""
    open static let SPEED_RET = ""
    
    // MARK Command Names between TS and iOS
    let IOS_CMD_SPEED_TEST:String = "speed_test"
    let IOS_CMD_WIFI_INFO:String = "wifi_info"
    let IOS_CMD_SYS_INFO:String = "sys_info"
    let IOS_CMD_OK = "ok"
    
    var bleMgr:BlueToothManager!
    var netInfo:NetInfoViewController!
    
    init(owner: NetInfoViewController) {
        netInfo = owner
        bleMgr = BlueToothManager(owner: self)
        
        if (bleMgr == nil) {
            Log.e(tag: TAG, string: "Failed to init blue tooth manager!!")
        }
    }
    
    func start() {
        DispatchQueue.global(qos: .background).async {
            while true {
                if (self.bleMgr.isReady) {
                    self.bleMgr.readFromBle()
                }
                
                // Sleep for some time
                usleep(1000)
            }
        }
    }
    
    public func sendMessage(data: String) {
        if (self.bleMgr != nil) {
            Log.d(tag: TAG, string: "sending data: \(data)")
            bleMgr.sendToBle(data: data)
        }
    }
    
    public func handleUpstreamData(data: String) {
        Log.d(tag: TAG, string: "Received command: \(data)")
        if (data == IOS_CMD_SPEED_TEST) {
            // Execute speed test
            print("Executing speed test!!")
        } else if (data == IOS_CMD_WIFI_INFO) {
            // Execute WiFi Info
            print("Executing WiFi Info!!")
        } else if (data == IOS_CMD_SYS_INFO) {
            // Execute sys info
            print("Executing Systen Info!!")
        }
        
        // Dummy
        if (netInfo != nil) {
            netInfo.handleUpstreamData(data: data)
        }
    }
}
