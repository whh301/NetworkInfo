//
//  FirebaseIDService.swift
//  NetworkInfo
//
//  Created by Wu Xiaohua on 8/20/18.
//  Copyright © 2018 Wu Xiaohua. All rights reserved.
//
/**
 * Created by root on 8/20/18.
 */

import Foundation
import UIKit
import Firebase

/*  this class is used for authentication
    types of Authentication:
    1. Firebase
    2. Hash file per day
    3. Spirent Cloud Licensing
*/
class FirebaseAuthentication {
    private let TAG:String = "LOGIN"
    private let license:String = "NetworkAnalyzer APP License Valid: "
    private var fileSignedIn:Bool = false;
    public static let AUTH_FIREBASE:Int = 1;
    public static let AUTH_FILE:Int = 2;
    public static let AUTH_CLOUD:Int = 3;

    public init(method: Int) {
        if (method == FirebaseAuthentication.AUTH_FIREBASE) {
            firebaseSignIn();
        }
        else if (method == FirebaseAuthentication.AUTH_FILE) {
            fileSignIn();
        }
        else if (method == FirebaseAuthentication.AUTH_CLOUD) {
            cloudSignIn();
        }
    }

    //FILE SIGN IN METHODS
    public func fileSignIn() {
        let sdf = DateFormatter()
        sdf.dateFormat = "yyyy-MM-dd"
        sdf.timeZone = TimeZone(identifier: "UTC")
        let currDate = Date()
        var calc = license + sdf.string(from: currDate)
//        Log.v(TAG, "calcToday:" + calc); //always keep this commented out

        let sha1CalcToday = calc.sha1().lowercased()

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: currDate)
        calc = license + sdf.string(from: yesterday!)
//        Log.v(TAG, "calcYesterday:" + calc); //always keep this commented out
        let sha1CalcYesterday = calc.sha1().lowercased()

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: currDate)
        calc = license + sdf.string(from: tomorrow!)
//        Log.v(TAG, "calcTomorrow:" + calc); //always keep this commented out
        let sha1CalcTomorrow = calc.sha1().lowercased()

        var sha1Read = "";
        let licenseFile = Log.readFile(filename: AdbService.LOCAL_DIR + AdbService.licenseFile);
        if (licenseFile != nil && !licenseFile.isEmpty && licenseFile.count > 40) {
            sha1Read = String(licenseFile.lowercased().prefix(40))
        }

//        Log.v(TAG, "license:" + sha1Calc + " : " + sha1Read); //always keep this commented out
        if (sha1Read == sha1CalcToday) {
            fileSignedIn = true;
            Log.v(tag: TAG, string: "license verified");
        }
        else if (sha1Read == sha1CalcYesterday) {
            fileSignedIn = true;
            Log.v(tag: TAG, string: "license verified");
        }
        else if (sha1Read == sha1CalcTomorrow) {
            fileSignedIn = true;
            Log.v(tag: TAG, string: "license verified");
        }
        else {
            fileSignedIn = false;
        }
    }

    public func isFileSignedIn() ->Bool {
        return fileSignedIn;
    }

    //CLOUD SIGN IN METHODS
    public func cloudSignIn() {
    }

    public func isCloudSignedIn() ->Bool {
        return false;
    }

    // FIREBASE SIGN IN METHODS
    // @SuppressLint("MissingPermission")
    private func getImei() ->String! {
        var ret = UIDevice.current.identifierForVendor?.uuidString as? String
        Log.Imei = ret!;
        return ret!;
    }

    private func getDomainNameAndGroupId() -> String {
        var ret = "spirent";

        //do {
            let readData = Log.readFile(filename: "\(AdbService.LOCAL_DIR)\(AdbService.account)");
            if (readData != nil && readData != "" && readData != "null") {
                ret = readData;
            }
            let account = ret.split(separator: ";")
            Log.AccountName = String(account[0])
            Log.v(tag: TAG, string: "accountname:" + Log.AccountName)

            if (account.count > 1) {
                Log.GroupId = String(account[1])
                Log.v(tag: TAG, string: "groupid:" + Log.GroupId)
            }
            if (account.count > 2) {
                Log.AlwaysOnService = Bool.init(String(account[2]))!
                Log.v(tag: TAG, string: "Always On Service: \(Log.AlwaysOnService)")
            }
            if (account.count > 3) {
                Log.LaunchAppOnBoot = Bool.init(String(account[3]))!;
                Log.v(tag: TAG, string: "Launch App On Boot: \(Log.LaunchAppOnBoot)")
            }
            if (account.count > 4) {
                Log.UploadResults = Bool.init(String(account[4]))!;
                Log.v(tag: TAG, string: "UploadResults: \(Log.UploadResults)")
            }
            if (account.count > 5) {
                Log.ReportResults = Bool.init(String(account[5]))!;
                Log.v(tag: TAG, string: "groupid: \(Log.ReportResults)")
            }
        //} catch {
        //    Log.w(tag: TAG, string: "getDomainName failed \(error)")
        //}

        return Log.AccountName;
    }

    public func firebaseSignIn() {
        let imei = getImei()
        //do {
            if Auth.auth().currentUser == nil {
                Auth.auth().signIn(withEmail: "\(imei)@\(getDomainNameAndGroupId()).com", password: imei!, completion: { (authResult, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        print("Firebase auth error")
                        Log.w(tag: "Signin Failed", string: error.localizedDescription)
                    } else {
                        print("Firebase login success")
                    }
                })
            }
        //} catch {
        //    Log.w(TAG, "signIn failed \(error)");
        //}
    }

    public func isfirebaseSignedIn() ->Bool {
        if Auth.auth().currentUser == nil {
            Log.r(tag: TAG, string: "LoggedIn");
            MyFirebaseMessagingService.subscribe(topic_: Log.AccountName);
            return true;
        } else {
            Log.r(tag: TAG, string: "LoggedOut");
            return false;
        }
    }

    public func firebaseSignOut() {
        Log.r(tag: TAG, string: "signOut");
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
            } catch {
                print(error)
            }
        }
    }
}

extension String {
    func sha1() ->String {
        let data = self.data(using: String.Encoding.utf8)
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
    
        
        data?.withUnsafeBytes {
            _ = CC_SHA1($0, CC_LONG.init(exactly: NSNumber.init(integerLiteral: (data?.count)!))!, &digest)
        }
    
        let hexBytes = digest.map{ String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
}
