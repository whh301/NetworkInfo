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
import UserNotifications
import Firebase

/*
TOKEN="er8AHmJpdlY:APA91bHy7f-pZfZ2KtMc6kr4f8wapfaP3v9G6amz1UHpE4y2nTGVhhINaeTjn28hWa5Qz3flfvoUbejPsWk8FMsZg2XmD5V87_ITNYYKTsupCcyf8656HT0sUFsT-NxJHDoW9lm_2buOqFqFxhu7LykfhtZnsc7ZAA"
API_KEY="AAAACZBEjHw:APA91bEH6CFmrqVLi-5elxKHX0jIgieBaocjONPmodMusFw5684QDSRTjavXAhc5VXWztPZutRJh2IEzaC4XfL0TDWDP7iQaIur1LXcZ5GPolxcmqAzdmpfCFSsmEG7xp2sZ2DQnDwPo"
curl -H "Content-type: application/json" -H "Authorization:key=${API_KEY}" -d "{ \"to\":\"${TOKEN}\", \"data\": { \"type\": \"test\", \"name\": \"mobile_info\", \"config\": \"\", \"log\": \"10\", \"timeout\": \"15000\" } }" -X POST https://fcm.googleapis.com/fcm/send
*/

class MyFirebaseMessagingService:UIResponder, UIApplicationDelegate {
    static let TAG:String = "MyFirebaseMessagingService"
    static let MESSAGE_TYPE_KEY:String = "type"
    static let MESSAGE_TYPE_REGISTER_REPLY:String = "register_reply"
    static let MESSAGE_RESULT:String = "result"
    static let MESSAGE_TYPE_TEST:String = "test"
    static let MESSAGE_TEST_NAME:String = "name"
    static let MESSAGE_TEST_CONFIG:String = "configuration"
    static let MESSAGE_TYPE_TIMEOUT:String = "timeout"
    static let MESSAGE_TYPE_LOG_LEVEL:String = "log"
    static let APP_SERVER:String = "41075117180@gcm.googleapis.com";

    let gcmMessageIDKey = "gcm.message_id"
    static let config_queue:NSMutableArray = NSMutableArray()
    static let MAX_QUEUE_SIZE:Int = 20

    //@Override
    public static func onMessageReceived(remoteMessage: MessagingRemoteMessage) {
        Log.i(tag: MyFirebaseMessagingService.TAG, string: "Remote Message Received");
        if (!remoteMessage.appData.isEmpty) {
            let type:String = remoteMessage.appData[MESSAGE_TYPE_KEY] as! String
            Log.i(tag: MyFirebaseMessagingService.TAG, string: "type: " + type)
            if (type.lowercased() == MESSAGE_TYPE_REGISTER_REPLY.lowercased()) {
                let result = remoteMessage.appData[MESSAGE_RESULT] as! String
                Log.i(tag: MyFirebaseMessagingService.TAG, string: "REGISTER_REPLY result: " + result)
            } else if (type.lowercased() == MESSAGE_TYPE_TEST.lowercased()) {
                var name = remoteMessage.appData[MESSAGE_TEST_NAME] as! String
                var config = remoteMessage.appData[MESSAGE_TEST_CONFIG] as! String
                var timeout = remoteMessage.appData[MESSAGE_TYPE_TIMEOUT] as! String
                var logLevel = remoteMessage.appData[MESSAGE_TYPE_LOG_LEVEL] as! String
                Log.i(tag: MyFirebaseMessagingService.TAG, string: "name: " + name + " config: " + config)

                if ( name.isEmpty ) {
                    name = AdbService.LTE_INFO_NAME
                }
                
                if ( config.isEmpty ) {
                    config = ""
                }
                
                if ( logLevel.isEmpty ) {
                    logLevel = "10"
                }
                
                if ( timeout.isEmpty ) {
                    timeout = "120000"
                }

                let data = """
                              <?xml version=\"1.0\"?> \(CharacterSet.newlines)
                              <ts_config>\(CharacterSet.newlines)
                                <ue>\(CharacterSet.newlines)
                                  <log en=\"true\" level=\"\(logLevel)\"/>\(CharacterSet.newlines)
                                </ue>\(CharacterSet.newlines)
                                <tests>\(CharacterSet.newlines)
                                  <test name=\"\(name)\" config=\"\(config)\" timeout=\"\(timeout)\"/>\(CharacterSet.newlines)
                                </tests>\(CharacterSet.newlines)
                              </ts_config>\(CharacterSet.newlines)
                            """

                if (!FileManager.default.fileExists(atPath: AdbService.CONFIG_FILE) && config_queue.count == 0) {
                    Log.WriteToFileQuick(filename: AdbService.CONFIG_FILE, data: data, append: false);
                } else {
                    if (config_queue.count < MAX_QUEUE_SIZE) {
                        config_queue.adding(data);
                        if (config_queue.count == 1) {
                            delayedReadFromQueue();
                        }
                    }
                }
            }
        }
    }

    private static func delayedReadFromQueue() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 20000, execute: {
            if (MyFirebaseMessagingService.config_queue.count > 0 && !(FileManager.default.fileExists(atPath: AdbService.CONFIG_FILE))) {
                Log.WriteToFileQuick(filename: AdbService.CONFIG_FILE, data: config_queue[0] as! String, append: false);
                
                MyFirebaseMessagingService.config_queue.removeObject(at: 0)
            }
                
            if (MyFirebaseMessagingService.config_queue.count > 0) {
                delayedReadFromQueue()
            }
        })
    }

    public static func subscribe(topic_: String) {
        Messaging.messaging().subscribe(toTopic: topic_);
        Log.d(tag: TAG, string: "subscribe(): " + topic_);
    }

    public static func unsubscribe(topic_: String) {
        Messaging.messaging().unsubscribe(fromTopic: topic_);
        Log.d(tag: TAG, string: "unsubscribe(): " + topic_);
    }

    public static func send(pattern_:String, state_:String,
                            api_:String, topic_:String) {
        let jGcmData:NSMutableDictionary = NSMutableDictionary()

        // to
        jGcmData.setValue("/topics/" + topic_, forKey: "to")
        // priority
        jGcmData.setValue("high", forKey: "priority")
        // data
        let innerData:NSMutableDictionary = NSMutableDictionary()
        innerData.setValue(pattern_ + "-" + state_, forKey: "state")
        jGcmData.setValue(innerData, forKey: "data")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jGcmData, options: JSONSerialization.WritingOptions.prettyPrinted) as NSData
            let jsonString = (NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue) as String?)!
            Log.d(tag: TAG, string: "send(): json: \(jsonString)");
        
            // Create connection to send GCM Message request.
            let urlPath:URL = URL(string: "https://fcm.googleapis.com/fcm/send")!
            let request: NSMutableURLRequest = NSMutableURLRequest(url: urlPath)
            request.httpMethod = "POST"
            request.httpBody = jsonData as Data
            
            request.setValue("key=" + api_, forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let response: AutoreleasingUnsafeMutablePointer<URLResponse?>? = nil
            try NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: response)
            print(response ?? "")
        } catch {
            print(error)
        }
    }

    public static func result_upload(local_: String, remote_: String) {
        // local file
        // "/sdcard/Android/data/com.spirent.networkanalyzer/" + RecFile
        // /sdcard/Android/data/com.spirent.networkanalyzer/voice_rec.wav
        let localUrl = URL.init(fileReferenceLiteralResourceName: local_)
        // remote file reference
        // Topic + "_" + Pattern.toLowerCase() + "_" + RecFile
        // cspirent.com_o_voice_rec.wav
        let storageRef = Storage.storage().reference(withPath: remote_)

        storageRef.putFile(from: localUrl, metadata:nil) {
            (metadata, error) in
            if let error = error {
                print("File \(local_) upload failed: \(error)")
            }
        }
    }

    public static func file_upload(local_: String, remote_: String, callback_: NSObject) {
        // local file
        let localUrl = URL.init(fileReferenceLiteralResourceName: local_)
        // remote file reference
        let storageRef = Storage.storage().reference(withPath: remote_)
        
        storageRef.putFile(from: localUrl, metadata:nil) { (metadata, error) in
            if let error = error {
                print("File \(local_) upload failed: \(error)")
            }
        }
    }

    public static func file_download(local_: String, remote_: String, callback_: NSObject) {
        // local file
        let localUrl = URL.init(fileReferenceLiteralResourceName: local_)
        // remote file reference
        let storageRef = Storage.storage().reference(withPath: remote_)
        
        storageRef.write(toFile: localUrl) { (url, error) in
            if let error = error {
                print("File \(remote_) download failed: \(error)")
            }
        }
    }

    public static func file_delete(remote_: String) {
        // remote file reference
        // Topic + "_" + Pattern.toLowerCase() + "_" + RecFile
        // cspirent.com_o_voice_rec.wav
        Log.d(tag: TAG, string: "file_delete(): " + remote_)
        let fileRef = Storage.storage().reference(withPath: remote_)
        // delete file
        fileRef.delete();
    }

    public static func result_send(content:String, test:String) {
        let rmtMsg:MessagingRemoteMessage = MessagingRemoteMessage()
        rmtMsg.setValue(Log.Imei, forKey: "imei")
        rmtMsg.setValue("type", forKey: "result")
        rmtMsg.setValue(test, forKey: "test_name")
        rmtMsg.setValue(content, forKey: "test_result")
        
        Messaging.messaging().sendMessage(rmtMsg.appData, to: APP_SERVER, withMessageID: "m-\(UUID().uuidString)", timeToLive: 1000)
    }

    // @Override
    public func onTokenRefresh() {
        //super.onTokenRefresh();
        Log.r(tag: MyFirebaseMessagingService.TAG, string: "onTokenRefresh()");
        MyFirebaseMessagingService.sendRegister();
    }

    public static func sendRegister() {
        // let refreshedToken = Firebase.getInstance().getToken();
        //        Log.v(TAG, "TOKEN: " + refreshedToken);
        if (Log.UploadResults || Log.ReportResults) {
            Messaging.messaging().sendMessage(["imei":Log.Imei, "type":"register"],
                to: APP_SERVER,
                withMessageID: "m-\(UUID().uuidString)",
                timeToLive: 1000)
            
            Log.r(tag: TAG, string: "sendRegister");
        }
    }
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension MyFirebaseMessagingService : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        // Change this to your preferred presentation option
        completionHandler([])
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        completionHandler()
    }
}

// [END ios_10_message_handling]
extension MyFirebaseMessagingService : MessagingDelegate {
    // [START refresh_token]
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
        onTokenRefresh()
    }
    
    // [END refresh_token]
    
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    public func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
        
        MyFirebaseMessagingService.onMessageReceived(remoteMessage: remoteMessage)
    }
    // [END ios_10_data_message]
}
