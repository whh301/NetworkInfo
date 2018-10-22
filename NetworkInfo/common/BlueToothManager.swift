//
//  BlueToothThread.swift
//  NetworkInfo
//
//  Created by Wu Xiaohua on 8/28/18.
//  Copyright © 2018 Wu Xiaohua. All rights reserved.
//

import Foundation

import CoreBluetooth

let BLUE_RMT_DEV_NAME: String = "blue_linux"
let BLUE_LCL_DEV_NAME: String = "blue_ios"

class BlueToothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var owner: AdbService!
    var central: CBCentralManager!
    var peerObj: CBPeripheral!
    var bleService: CBService!
    var bleTerm: CBCharacteristic!
    
    var isReady:Bool = false;
    
    init(owner: AdbService) {
        super.init()
        
        let centralQueue: DispatchQueue = DispatchQueue(label: "com.spirent.bleQueue", attributes: .concurrent)
        central = CBCentralManager(delegate: self, queue: centralQueue)
        
        self.owner = owner
    }
    
    func sendToBle(data: String) {
        if (peerObj != nil) {
            peerObj.writeValue(data.data(using: String.Encoding.utf8)!, for: bleTerm, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    func readFromBle() {
        if (peerObj != nil) {
            peerObj.readValue(for: self.bleTerm)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Bluetooth status is UNKNOWN")
        case .resetting:
            print("Bluetooth status is RESETTING")
        case .unsupported:
            print("Bluetooth status is UNSUPPORTED")
        case .unauthorized:
            print("Bluetooth status is UNAUTHORIZED")
        case .poweredOff:
            print("Bluetooth status is POWERED OFF")
        case .poweredOn:
            print("Bluetooth status is POWERED ON")
            
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral.name!)
        
        if advertisementData["kCBAdvDataLocalName"] != nil && advertisementData["kCBAdvDataLocalName"] as! String == BLUE_RMT_DEV_NAME {
            central.stopScan()
            
            self.peerObj = peripheral
            peripheral.delegate = self
            central.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected\n");
        
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("\ndevice[\(peripheral.identifier.uuidString)] Disconnect\n")
        print("Please restart app\n");
        
        //[[ViewController singleton] terminal_quit];
        self.bleTerm = nil
        self.peerObj = nil
        self.central = nil
        self.isReady = false
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for i in 0..<peripheral.services!.count {
            let cbSrv:CBService = peripheral.services![i]
            if cbSrv.uuid.uuidString == "1111" {
                self.bleService = cbSrv
                peripheral.discoverCharacteristics(nil, for: cbSrv)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for i in 0..<peripheral.services!.count {
            let eachCharc:CBCharacteristic = service.characteristics![i]
            
            if eachCharc.uuid.uuidString == "2222" {
                self.bleTerm = eachCharc
            }
        }
        
        self.isReady = true
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            print("read failed: @\(String(describing: error?.localizedDescription))")
        }
        
        let readVal:String = String.init(data: characteristic.value!, encoding: String.Encoding.utf8)!
        
        self.owner.handleUpstreamData(data: readVal)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            print("Write error: @\(error?.localizedDescription)")
        }
        
        // Writing done
    }
}

