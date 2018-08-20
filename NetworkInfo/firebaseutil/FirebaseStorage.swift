//
//  FirebaseStorage.swift
//  NetworkInfo
//
//  Created by Wu Xiaohua on 8/20/18.
//  Copyright © 2018 Wu Xiaohua. All rights reserved.
//

import Foundation
import Firebase

open class FirebaseStorage {
    
    // Firebase storage configuration
    lazy var storage = Storage.storage()
    
    // single instance
    static var instance = FirebaseStorage()
    
    private func FireBaseStorage() {
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { (authResult, error) in
                if let error = error {
                    print(error.localizedDescription)
                    print("Firebase auth error")
                } else {
                    print("Firebase login success")
                }
            }
        }
    }
    
    open static func getInstance() -> FirebaseStorage {
        return instance;
    }
    
    open func saveFile(fileName:String) {
        let localUrl = URL.init(fileReferenceLiteralResourceName: fileName)
        let filePath = Auth.auth().currentUser!.uid + "/\(localUrl.lastPathComponent)"
        
        let storageRef = self.storage.reference(withPath: filePath)
        storageRef.putFile(from: localUrl, metadata:nil) {
            (metadata, error) in
            if let error = error {
                print("File \(fileName) upload failed: \(error)")
            }
        }
    }
}
