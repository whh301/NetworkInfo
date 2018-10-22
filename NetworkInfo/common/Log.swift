//
//  Log.swift
//  NetworkInfo
//
//  Created by Wu Xiaohua on 8/20/18.
//  Copyright © 2018 Wu Xiaohua. All rights reserved.
//

import Foundation

open class Log {
    public static var MIN_LEVEL:Int = 4
    public static var MAX_LEVEL:Int = 12
    private static var LEVEL:Int = MIN_LEVEL
    public static var TAG = "LOG";
    public static var LOG_FILE = "log file";
    
    public static var AccountName = "spirent";
    public static var GroupId = "0";
    public static var AlwaysOnService:Bool = false;
    public static var LaunchAppOnBoot:Bool = false;
    public static var UploadResults:Bool = true;
    public static var ReportResults:Bool = true;
    //currently wifi stats are only recorded if UploadResults or ReportResults, this needs to change
    
    public static var Imei = "";
    private static var FCM_STORAGE_RETRY = 2;
    private static var createdFiles = NSMutableSet();
    private static var uploadRetryCount = 0;
    
    public static func setLogLevel(level: Int) {
        Log.i(tag: TAG, string: "SET LOGGING level=\(level)")
        if (level < MIN_LEVEL) {
            LEVEL = MIN_LEVEL
        } else {
            LEVEL = level;
        }
    }
    
    public static func getLogLevel() -> Int {
        return LEVEL;
    }
    
    public static func e(tag: String, string: String) {
        if (LEVEL >= 1) {
            // MARK TODO IOS LOG UTIL
            //android.util.Log.e(tag, string)
            lsprint(level: "E", tag: tag, string: string)
        }
    } //1
    
    public static func r(tag: String, string: String) {
        if (LEVEL >= 2) {
            // MARK TODO IOS LOG UTIL
            //android.util.Log.e(tag, string)
            lsprint(level: "R", tag: tag, string: string)
        }
    } //2
    
    public static func w(tag: String, string: String) {
        if (LEVEL >= 3) {
            // MARK TODO IOS LOG UTIL
            //android.util.Log.e(tag, string)
            lsprint(level: "W", tag: tag, string: string)
        }
    } //3
    
    public static func i(tag: String, string: String) {
        if (LEVEL >= 4) {
            // MARK TODO IOS LOG UTIL
            //android.util.Log.e(tag, string)
            lsprint(level: "I", tag: tag, string: string)
        }
    } //4
    
    public static func d(tag: String, string: String) {
        if (LEVEL >= 5) {
            // MARK TODO IOS LOG UTIL
            //android.util.Log.e(tag, string)
            lsprint(level: "D", tag: tag, string: string)
        }
    } //5
    
    public static func d2(tag: String, string: String) {
        if (LEVEL >= 6) {
            // MARK TODO IOS LOG UTIL
            //android.util.Log.e(tag, string)
            lsprint(level: "D2", tag: tag, string: string)
        }
    } //6
    
    public static func d7(tag: String, string: String) {
        if (LEVEL >= 7) {
            // MARK TODO IOS LOG UTIL
            //android.util.Log.e(tag, string)
            lsprint(level: "D7", tag: tag, string: string)
        }
    } //7
    
    public static func d8(tag: String, string: String) {
        if (LEVEL >= 8) {
            // MARK TODO IOS LOG UTIL
            //android.util.Log.e(tag, string)
            lsprint(level: "D8", tag: tag, string: string)
        }
    } //8
    
    public static func d9(tag: String, string: String) {
        if (LEVEL >= 9) {
            // MARK TODO IOS LOG UTIL
            //android.util.Log.e(tag, string)
            lsprint(level: "D9", tag: tag, string: string)
        }
    } //9
    
    public static func d10(tag: String, string: String) {
        if (LEVEL >= 10) {
            // MARK TODO IOS LOG UTIL
            //android.util.Log.e(tag, string)
            lsprint(level: "D10", tag: tag, string: string)
        }
    } //10
    
    public static func d11(tag: String, string: String) {
        if (LEVEL >= 11) {
            // MARK TODO IOS LOG UTIL
            //android.util.Log.e(tag, string)
            lsprint(level: "D11", tag: tag, string: string)
        }
    } //11
    
    public static func v(tag: String, string: String) {
        if (LEVEL >= 12) {
            // MARK TODO IOS LOG UTIL
            //android.util.Log.e(tag, string)
            lsprint(level: "V", tag: tag, string: string)
        }
    } //12
    
    public static func e(tag: String, string: String, e: exception) {
        if (LEVEL >= 1) {
            // MARK TODO IOS LOG UTIL
            //android.util.Log.e(tag, string)
            // MARK TODO IOS DUMP EXCEPTION
        }
    } //Exception
    
    public static func getUTCTime() -> String {
        let sdf = DateFormatter()
        sdf.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"
        sdf.locale = Locale(identifier: "UTC")
        return sdf.string(from: Date());
    }
    
    public static func getUTCTime(time: Int64) -> String {
        let sdf = DateFormatter()
        sdf.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"
        sdf.locale = Locale(identifier: "UTC")
        return sdf.string(from: Date(timeIntervalSince1970: TimeInterval(time)))
    }
    
    public static func getTimezoneOffset() ->Int {
        let offset = TimeZone.current.secondsFromGMT()
        return offset / 3600;
    }
    
    public static func lsprint(level: String, tag: String, string: String) {
        let data = getUTCTime() + tag + "] " + level + " : " + string + "\n"
        WriteToFileQuick(filename: LOG_FILE, data: data, append: true)
    }
    
    public static func WriteToFileQuick(filename: String, data: String, append: Bool) {
        if !append {
            createdFiles.remove(filename)
        }
    
        createdFiles.adding(filename)
        Log.v(tag: TAG, string: "Added File to list:" + filename + " Size: \(createdFiles.count)");
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileUrl = docDir.appendingPathComponent(filename)
        do {
            try Data(data.utf8).write(to: fileUrl)
        } catch {
            print(error)
            createdFiles.remove(filename)
            return
        }
    
        if ((data == "Completed") || data == "Completed\(CharacterSet.newlines)") {
            if (ReportResults) {
                sendResult(filename: filename)
            }
            
            if (UploadResults) {
                uploadFile(filename: filename)
            }
        }
    }
    
    public static func CleanCreateFileHistory() {
        Log.v(tag: TAG, string: "CleanCreateFileHistory")
        createdFiles.removeAllObjects()
    }
    
    public static func deleteFile(filename: String) {
        do {
            if FileManager.default.fileExists(atPath: filename) {
               try FileManager.default.removeItem(atPath: filename)
            }
            
            createdFiles.remove(filename);
        } catch {
            print(error)
        }
    }
    
    public static func readFile(filename: String) -> String {
        Log.v(tag: TAG, string: "readFile");
        let readRst = ""
    
        do {
            let readRst = try NSString(contentsOfFile: filename, encoding: String.Encoding.utf8.rawValue)
        } catch {
            print(error)
        }
        return readRst
    }
    
    public static func onUploadCallback(success_: Bool, filename: String) {
        Log.d(tag: TAG, string: "onUploadCallback(): \(success_)")
        if (success_) {
            // remove file
            deleteFile(filename: filename)
        } else {
            // upload file to google storage, done on callback onUploadCallback()
            uploadFile(filename: filename)
        }
    }
    
    private static func uploadFile(filename: String) {
        // try upload up to FCM_STORAGE_RETRY, otherwise indicate error state
        if (uploadRetryCount < FCM_STORAGE_RETRY) {
            // upload file to google storage, done on callback onUploadCallback()
            let fileUrl = URL.init(fileURLWithPath: filename, isDirectory: false)
            let remote = "\(AccountName)/\(Imei)/\(fileUrl.lastPathComponent)"
            uploadRetryCount = uploadRetryCount + 1

            //var logStr = "uploadFile: \(uploadRetryCount)"
            //logStr = logStr + " local: \(filename)"
            //logStr = logStr + " remote: \(remote)"
            //Log.d(tag: TAG, string: logStr)
            
            // New TASK to upload file
            DispatchQueue.main.async(execute: {
                MyFirebaseMessagingService.file_upload(local_: filename, remote_: remote, callback_: NSObject())
            })
        } else {
            // set state / notify ERROR to TS
            Log.e(tag: TAG, string: "uploadFile(): upload failed, retry exceeded!");
        }
    }
    
    private static func sendResult(filename: String) {
        //        ts_mobile_info_result.ret
        let fileUrl = URL.init(fileURLWithPath: filename, isDirectory: false)
        let test = fileUrl.lastPathComponent
        let content = readFile(filename: filename)
        
        // NEW TASK to send data
        DispatchQueue.main.async(execute: {
            MyFirebaseMessagingService.result_send(content: content, test: test)
        })
    }
}
