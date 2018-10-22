//
//  FirebaseIDService.swift
//  NetworkInfo
//
//  Created by Wu Xiaohua on 8/20/18.
//  Copyright © 2018 Wu Xiaohua. All rights reserved.
//
/**
 * Created by root on 8/22/18.
 */

import Foundation

class OSpeedCommandHelper {
    let TAG:String = "OSTCommandHelper"
    let OOKLA_TAG:String = "OOKLA_OUT"
    
    var ostTask:DispatchWorkItem!
    var mRunning:Bool = false
    var testRecordCompleted:Bool = false;
    var myactivity:OSpeedViewController!
    var editHelper:OSpeedEditConfigHelper!
    var resolveServer:OSpeedTestResolve!
    var initTime:Int64 = 0
    var commandHelper:OSpeedCommandHelper!
    
    //parseLog variables
    var latency:Int = 0
    var serverid:Int = 0
    var upload:Double = 0.0
    var download:Double = 0.0
    var upload_start:String = ""
    var download_start:String = ""
    var upload_bytes:Int64 = 0
    var download_bytes:Int64 = 0
    var upload_duration:Int = 0
    var download_duration:Int = 0
    var offset:Int = 0
    var upload_mbps:Double = 0.0
    var download_mbps:Double = 0.0

    public init(activity: OSpeedViewController)  {
        setDefaults(isInit: true)

        myactivity = activity
        editHelper = myactivity.editHelper

        commandHelper = self;
    }

    private func setDefaults(isInit: Bool) {
        if (isInit) {
            ostTask = nil
            mRunning = false
            myactivity = nil
            editHelper = nil
            resolveServer = nil
            commandHelper = nil
        }

        testRecordCompleted = false;
        initTime = 0;

        //parseLog variables
        latency = 0
        serverid = 0
        upload = 0.0
        download = 0.0
        upload_start = ""
        download_start = ""
        upload_bytes = 0
        download_bytes = 0
        upload_duration = 0
        download_duration = 0
        offset = 0
        upload_mbps = 0.0
        download_mbps = 0.0
    }

    //This method is used to handle toggle button clicks
    public func ToggleButtonClick() {
        if (myactivity != nil) {
            let startBtn = myactivity.btnAction
            Log.d(tag: TAG, string: "Toggle click \(String(describing: startBtn?.isSelected))")
            //If the button is not pushed (waiting for starting a test), then a iperf task is started.
            if (startBtn?.isSelected)! {
                Log.d(tag: TAG, string: "Calling init")
                initOSpeedTest()
                myactivity.isTestRunning = true;
                //If a test is already running then a cancel command is issued through the OSTTask interface.
            } else {
                myactivity.isTestRunning = false
                startBtn?.isSelected = false
                if (ostTask == nil) {
                    Log.d(tag: TAG, string: "no task");
                    return;
                }
                Log.d(tag: TAG, string: "I am cancelling");
                cancelOSTTask();
            }
        }
    }

    public func cancelOSTTask() {
        mRunning = false;
        if (ostTask != nil) {
            //ostTask.suspend()
            //For some reason onCancelled() is not being called implicitly from the above call
            //ostTask.finalize()
            ostTask = nil
            resolveServer = nil
        }
    }
    
    public func initOSpeedTest() {
        Log.d(tag: TAG, string: "in init file exists");
        if (myactivity != nil) {
            let statusView = myactivity.txtLogInfo
            let progress = myactivity.progressView

            statusView?.text = "Resolving Best Server ..."
            progress?.setProgress(0.0, animated: true)
        }

        mRunning = true;
        editHelper.servers = nil
        
        /*
        ostTask = DispatchWorkItem {
            Log.d(TAG, "in async task doinbackground");
            let str = getCommandfromConfig();
            
            let task = Process()
            task.lunchPath = editHelper.APP_PATH + "ookla"
            
            let pipe = Pipe()
            task.standardOutput = pipe
            
            //task.
            
            //The output text is accumulated into a string buffer and published to the GUI
        }
        */
        
        clearLog()
        resolveServer = OSpeedTestResolve(a: myactivity, c: commandHelper);
        writeToTsFile(data: "offsetTz=\(Log.getTimezoneOffset())\n", append: false);

        //delayed Resolving Best server to let the run function return before all heavy lifting starts
        if (myactivity != nil) {
            //DispatchQueue.main.async {
                if self.resolveServer.resolveServersFromConfigUrl(searchParms: "", append: false) {
                    self.myactivity.txtLogInfo.text = "Running Ping Test ..."
                    self.myactivity.progressView.setProgress(10.0, animated: true)
                    self.writeToTsFile(data: "Resolve Server Completed\n", append: true);
                    self.writeToTsFile(data: "speed_tech_start= \(self.getActiveNetworkType())\n");
                    Log.d(tag: self.TAG, string: "call execute")
                    
                    // Execute now
                    //DispatchQueue.main.async(execute: self.ostTask)
                } else {
                    self.cancelOSTTask();
                    self.myactivity.txtLogInfo.text = "Error Resolving Server!"
                    self.myactivity.progressView.setProgress(100.0, animated: true)
                    
                    Log.e(tag: self.TAG, string: "Resolve Server Failed.")
                    self.writeToTsFile(data: "Resolve Server Failed\n", append: false)
                }
            //}
        }
        else
        {
            if (resolveServer.resolveServersFromConfigUrl(searchParms: "", append: false)) {
                writeToTsFile(data: "Resolve Server Completed\n", append: true);
                writeToTsFile(data: "speed_tech_start=" + getActiveNetworkType() + "\n");
                Log.d(tag: TAG, string: "call execute");
                ostTask.perform()
            } else {
                cancelOSTTask();
                Log.e(tag: TAG, string: "Resolve Server Failed.");
                writeToTsFile(data: "Resolve Server Failed\n", append: false);
            }
        }

        return;
    }

    public func clearLog() {
        setDefaults(isInit: false)
        
        if myactivity == nil {
            Log.WriteToFileQuick(filename: OSpeedEditConfigHelper.SCHEDULED_LOG_FILE, data: "", append: false);
        } else {
            var logOutput = myactivity.txtLogInfo
            if (logOutput != nil) {
                logOutput?.text = ""
            }

            let latn = myactivity.lblLatency
            let dwnl = myactivity.lblDlSpeed
            let upl = myactivity.lblUlSpeed
            let svr = myactivity.lblServerName

            latn?.text = ""
            dwnl?.text = ""
            upl?.text = ""
            svr?.text = ""
        }

        startSaveCurrentLog();
    }

    private func addToLog(log: String) {
        do {
            if (!log.contains("%")) {
                Log.d10(tag: OOKLA_TAG, string: log);

                if (myactivity != nil) {
                    let logOutput = myactivity.txtLogInfo
                    
                    if (logOutput != nil) {
                        logOutput?.text = (logOutput?.text)! + log
                    }
                }
                parseLog(log: log);
            }
        } catch {
            Log.w(tag: TAG, string: "Add to log failed \(error)")
        }
    }

    private func startSaveCurrentLog() {
        var yourmilliseconds = TimeZone.current.secondsFromGMT()
        var sdf = DateFormatter()
        sdf.dateFormat = "MMM dd,yyyy HH:mm"
        var resultdate = Date(timeIntervalSince1970: Double(yourmilliseconds));

        if (myactivity == nil) {
            var fileName = OSpeedEditConfigHelper.SCHEDULED_LOG_FILE;
            Log.WriteToFileQuick(filename: fileName, data: sdf.string(from: resultdate)  + "\n\n", append: true);
            Log.WriteToFileQuick(filename: fileName, data: "**********Configuration************\n\n", append: true);
            Log.WriteToFileQuick(filename: fileName, data: editHelper.getConfig() + "\n\n", append: true);
            Log.WriteToFileQuick(filename: fileName, data: "***************Log*****************\n", append: true);
        }
    }

    private func copyAsset() ->Bool {
        Log.d(tag: TAG, string: "copyAsset");
        var ret = false;
        //TODO: enable copy by service
        if (myactivity == nil) { return ret; } //if CommandHelper is called by service
        
        do {
            if FileManager.default.fileExists(atPath: OSpeedEditConfigHelper.APP_PATH + "ookla") {
                try FileManager.default.removeItem(atPath: OSpeedEditConfigHelper.APP_PATH + "ookla")
            }
        
            // @TODO Copy from resounce to local dir
        } catch let error {
            Log.e(tag: TAG, string: "Error while copying. \(error.localizedDescription)")
        }

        ret = true;
        return ret;
    }

    private func writePassFailToFile() {
        if (testRecordCompleted) {
            return
        } else {
            testRecordCompleted = true
        }

        if ((download_mbps > 0) && (upload_mbps > 0)) {
            writeToTsFile(data: "speed_tech_end=" + getActiveNetworkType() + "\n");
            writeToTsFile(data: "Completed");
        } else {
            writeToTsFile(data: "speed_tech_end=" + getActiveNetworkType() + "\n");
            writeToTsFile(data: "Failed");
        }
    }

    func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: NSRegularExpression.Options.caseInsensitive)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    private func parseLog(log: String)  {
        do {
            var dwnlVerifyString = (editHelper.uploadfirst == 0) ? "Starting stage 2" : "Starting stage 3";
            var uplVerifyString = (editHelper.uploadfirst == 1) ? "Starting stage 2" : "Starting stage 3";

            var test = log;
            var temp = test.split(separator: "\n")
            for i in 0..<temp.count {
                if (temp[i] == "") { continue }

                //get ServerID
                if (String(temp[i]).starts(with: "serverid")) {
                    let pattern = "serverid:[\\s\\t]+([\\d]+)"
                    let m = matches(for: pattern, in: String(temp[i]))
                    
                    if (m.count > 0) {
                        serverid = Int(m[0])!
                    }
                    writeToTsFile(data: "server_id=\(serverid)\n", append: true);

                    if (serverid != 0) {
                        //get Other Server details
                        let s = editHelper.getServerDetails(id: serverid)

                        if (myactivity != nil) {
                            myactivity.lblServerName.text = "\(serverid);" + ((s != nil && s?.sponsor != nil) ? (s?.sponsor)!:"")
                        }
                        if (s != nil) {
                            if (s?.host != nil) {
                                writeToTsFile(data: "host=" + (s?.host)! + "\n");
                            }
                            if (s?.name != nil && s?.country != nil) {
                                writeToTsFile(data: "server=\(String(describing: s?.name.replacingOccurrences(of: ",", with: ""))) \(String(describing: s?.country.replacingOccurrences(of: ",", with: "")))\n");
                            }
                            if (s?.sponsor != nil) {
                                writeToTsFile(data: "sponsor=\(String(describing: s?.sponsor))\n");
                            }

                            if (myactivity != nil && s?.sponsor != nil && s?.name != nil)
                            {
                                myactivity.lblServerName.text = "\(String(describing: s?.sponsor)) ,\(String(describing: s?.name))"
                            }
                        }
                    }
                }
                //get Latency
                else if (String(temp[i]).starts(with: "latency")) {
                    let pattern = "latency:[\\s\\t]+([\\d]+)"
                    let m = matches(for: pattern, in: String(temp[i]))
                    if (m.count > 0) {
                        latency = Int(m[0])!;
                    }
                    writeToTsFile(data: "latency_ms=\(latency)\n");

                    if (myactivity != nil)
                    {
                        myactivity.lblTestStatus.text = "Running Download Test..." //next test is Download
                        myactivity.progressView.setProgress(25, animated: true)
                        myactivity.lblLatency.text = "\(latency) ms"
                    }
                }
                //get Upload
                else if (String(temp[i]).starts(with: "upload")) {
                    let pattern = "upload:[\\s\\t]+([\\d]+)";
                    let m = matches(for: pattern, in: String(temp[i]))
                    if (m.count > 0) {
                        upload = Double(m[0])!;
                        upload = upload / 1000; //mbps
                    }
                    writeToTsFile(data: "ookla_upload_mbps=\(upload)\n");

                    if (myactivity != nil)
                    {
                        myactivity.lblTestStatus.text = "Calculating Test Results..." //next test is upload results to speedtest
                        myactivity.progressView.setProgress(95, animated: true);
                        myactivity.lblUlSpeed.text = "\(upload)  mbps"
                    }

                    //upload duration
                    upload_duration = editHelper.testlength * 1000; //ms
                    writeToTsFile(data: "upload_duration=\(upload_duration)\n");
                }
                //get Download
                else if (String(temp[i]).starts(with: "download")) {
                    let pattern = "download:[\\s\\t]+([\\d]+)";
                    let m = matches(for: pattern, in: String(temp[i]));
                    if (m.count > 0) {
                        download = Double(m[0])!;
                        download = download / 1000; //mbps
                    }
                    writeToTsFile(data: "ookla_download_mbps=\(download)\n");

                    if (myactivity != nil)
                    {
                        myactivity.lblTestStatus.text = "Running Upload Test ..." //next test is Upload
                        myactivity.progressView.setProgress(60, animated: true)
                        myactivity.lblDlSpeed.text = "\(download)  mbps"
                    }

                    //upload duration
                    download_duration = editHelper.testlength * 1000; //ms
                    writeToTsFile(data: "download_duration=\(download_duration) \n");
                }
                //get Upload start time
                else if (temp[i].contains(uplVerifyString)) {
                    let pattern = "\\[([\\d\\-.:\\s\\t]+)\\][\\s\\t]+\\[info\\][\\s\\t]+" + uplVerifyString
                    let m = matches(for:pattern, in: String(temp[i]))
                    if (m.count > 0) {
                        upload_start = m[0]
                        upload_start = upload_start.replacingOccurrences(of: "-", with: "/");
                    }
                    
                    writeToTsFile(data: "upload_start=\(upload_start)\n")
                }
                //get Download start time
                else if (temp[i].contains(dwnlVerifyString)) {
                    let pattern = "\\[([\\d\\-.:\\s\\t]+)\\][\\s\\t]+\\[info\\][\\s\\t]+" + dwnlVerifyString
                    let m = matches(for:pattern, in: String(temp[i]))
                    if (m.count > 0) {
                        download_start = m[0]
                        download_start = download_start.replacingOccurrences(of: "-", with: "/")
                    }
                    
                    writeToTsFile(data: "download_start=\(download_start)\n")
                }
                //get Upload Bytes
                else if (temp[i].contains("total bytes uploaded")) {
                    let pattern = "total bytes uploaded:[\\s\\t]+([\\d]+)"
                    let m = matches(for:pattern, in: String(temp[i]))
                    if (m.count > 0) {
                        upload_bytes = Int64(m[0])!
                    }
                    writeToTsFile(data: "upload_bytes=\(upload_bytes)\n");

                    upload_mbps = (Double) (upload_bytes * 8) / (Double) (upload_duration * 1000); //in mbps
                    writeToTsFile(data: "upload_mbps=\(upload_mbps)\n");

                    writePassFailToFile();
                }
                //get Download Bytes
                else if (temp[i].contains("total bytes downloaded")) {
                    let pattern = "total bytes downloaded:[\\s\\t]+([\\d]+)";
                    let m = matches(for: pattern, in: String(temp[i]))
                    if (m.count > 0) {
                        download_bytes = Int64(m[0])!
                    }
                    
                    writeToTsFile(data: "download_bytes=\(download_bytes)\n");
                    download_mbps = (Double) (download_bytes * 8) / (Double) (download_duration * 1000); //in mbps
                    writeToTsFile(data: "download_mbps=\(download_mbps)\n")
                }
                else if (log.contains("Error occurred while accessing system resources") || log.contains("Cancelling Test") || log.contains("Test is done")){
                    writePassFailToFile();
                    if (myactivity != nil)
                    {
                        myactivity.lblTestStatus.text = "Test Finished" //next test is Upload
                        myactivity.progressView.setProgress(100, animated: true)
                    }
                }
            }

        }
        catch let error {
            Log.e(tag: TAG, string: "Failed ParseLog \(error.localizedDescription)")
        }
    }

    private func writeToTsFile(data: String) {
        writeToTsFile(data: data, append: true)
    }

    private func writeToTsFile(data: String, append: Bool) {
        Log.r(tag: TAG, string: data);
        Log.WriteToFileQuick(filename: AdbService.SPEED_RET, data: data, append: append);
    }

    private func getActiveNetworkType() ->String {

        
        return "UNKNOWN";
    }

    //in runs now the final output is changed to do download first, so the stage numbers in test are not correct
    //to match this test log, change uploaadfirst flag to 1 in editconfighelper
    public static let testLog:[String] = [
            "./ookla [2017-06-05 17:10:19.721] [info] added server id: 3894\n",
            "\turl: http://sfo.speedtest.net/speedtest/\n",
            "\tupload: /upload.php\n",
            "\thost: sfo.speedtest.net\n",
            "\tpath: /speedtest/upload.php\n",
            "\tport: 80\n",
            "[2017-06-05 17:10:19.721] [info] added server id: 935\n",
            "\thost: wdc.speedtest.net\n",
            "\tport: 8080\n",
            "[2017-06-05 17:10:19.721] [info] added server id: 2855\n",
            "\thost: ams.speedtest.net\n",
            "\tport: 8080\n",
            "[2017-06-05 17:10:19.721] [info] added server id: 10153\n",
            "\thost: kansas-city.speedtest.centurylink.net\n",
            "\tport: 8080\n",
            "[2017-06-05 17:10:19.721] [info] Server count: 4\n",
            "[2017-06-05 17:10:19.722] [info] Configuration expiry date: 1509235200\n",
            "[2017-06-05 17:10:19.722] [info] app.version: 3.5.1-310\n",
            "[2017-06-05 17:10:19.722] [info] resolving sfo.speedtest.net\n",
            "[2017-06-05 17:10:19.723] [info] connecting to port 80\n",
            "[2017-06-05 17:10:19.723] [info] waiting for connection\n",
            "[2017-06-05 17:10:19.778] [info] connection successful\n",
            "[2017-06-05 17:10:19.778] [info] socket connected: 3\n",
            "[2017-06-05 17:10:19.835] [info] received 'HTTP/1.1 200 OK\n",
            "Date: Mon, 05 Jun 2017 22:10:19 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:19.835] [info] latency sample: 56\n",
            "[2017-06-05 17:10:19.890] [info] received 'HTTP/1.1 200 OK\n",
            "Date: Mon, 05 Jun 2017 22:10:19 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:19.890] [info] latency sample: 54\n",
            "[2017-06-05 17:10:19.945] [info] received 'HTTP/1.1 200 OK\n",
            "Date: Mon, 05 Jun 2017 22:10:19 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:19.945] [info] latency sample: 55\n",
            "[2017-06-05 17:10:19.998] [info] received 'HTTP/1.1 200 OK\n",
            "Date: Mon, 05 Jun 2017 22:10:19 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:19.998] [info] latency sample: 52\n",
            "[2017-06-05 17:10:20.049] [info] received 'HTTP/1.1 200 OK\n",
            "Date: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:20.049] [info] latency sample: 51\n",
            "[2017-06-05 17:10:20.049] [info] latency measured for server 3894: 54147\n",
            "[2017-06-05 17:10:20.050] [info] new lowest latency server (id=3894) found with latency 54147\n",
            "[2017-06-05 17:10:20.050] [info] resolving wdc.speedtest.net\n",
            "[2017-06-05 17:10:20.051] [info] connecting to port 8080\n",
            "[2017-06-05 17:10:20.051] [info] waiting for connection\n",
            "[2017-06-05 17:10:20.104] [info] connection successful\n",
            "[2017-06-05 17:10:20.104] [info] socket connected: 4\n",
            "[2017-06-05 17:10:20.483] [info] received 'PONG 1496700620200\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:20.483] [info] latency sample: 322\n",
            "[2017-06-05 17:10:20.530] [info] received 'PONG 1496700620513\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:20.530] [info] latency sample: 47\n",
            "[2017-06-05 17:10:20.568] [info] received 'PONG 1496700620552\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:20.568] [info] latency sample: 37\n",
            "[2017-06-05 17:10:20.608] [info] received 'PONG 1496700620592\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:20.608] [info] latency sample: 39\n",
            "[2017-06-05 17:10:20.645] [info] received 'PONG 1496700620630\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:20.645] [info] latency sample: 37\n",
            "[2017-06-05 17:10:20.645] [info] latency measured for server 935: 96981\n",
            "[2017-06-05 17:10:20.645] [info] resolving ams.speedtest.net\n",
            "[2017-06-05 17:10:20.646] [info] connecting to port 8080\n",
            "[2017-06-05 17:10:20.646] [info] waiting for connection\n",
            "[2017-06-05 17:10:20.813] [info] connection successful\n",
            "[2017-06-05 17:10:20.813] [info] socket connected: 5\n",
            "[2017-06-05 17:10:21.135] [info] received 'PONG 1496700621066\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:21.135] [info] latency sample: 161\n",
            "[2017-06-05 17:10:21.290] [info] received 'PONG 1496700621223\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:21.290] [info] latency sample: 155\n",
            "[2017-06-05 17:10:21.445] [info] received 'PONG 1496700621378\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:21.445] [info] latency sample: 154\n",
            "[2017-06-05 17:10:21.601] [info] received 'PONG 1496700621534\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:21.601] [info] latency sample: 155\n",
            "[2017-06-05 17:10:21.755] [info] received 'PONG 1496700621688\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:21.755] [info] latency sample: 153\n",
            "[2017-06-05 17:10:21.755] [info] latency measured for server 2855: 156289\n",
            "[2017-06-05 17:10:21.755] [info] resolving kansas-city.speedtest.centurylink.net\n",
            "[2017-06-05 17:10:21.755] [info] connecting to port 8080\n",
            "[2017-06-05 17:10:21.755] [info] waiting for connection\n",
            "[2017-06-05 17:10:21.797] [info] connection successful\n",
            "[2017-06-05 17:10:21.797] [info] socket connected: 6\n",
            "[2017-06-05 17:10:21.872] [info] received 'PONG 1496700621858\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:21.872] [info] latency sample: 39\n",
            "[2017-06-05 17:10:21.899] [info] received 'PONG 1496700621891\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:21.899] [info] latency sample: 26\n",
            "[2017-06-05 17:10:21.927] [info] received 'PONG 1496700621919\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:21.928] [info] latency sample: 28\n",
            "[2017-06-05 17:10:21.954] [info] received 'PONG 1496700621945\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:21.954] [info] latency sample: 25\n",
            "[2017-06-05 17:10:21.980] [info] received 'PONG 1496700621972\n",
            "te: Mon, 05 Jun 2017 22:10:20 GMT\n",
            "Server: Apache/2.4.10 (Debian)\n",
            "Content-Length: 8\n",
            "Content-Type: text/html; charset=UTF-8\n",
            "\n",
            "size=500'\n",
            "[2017-06-05 17:10:21.980] [info] latency sample: 26\n",
            "[2017-06-05 17:10:21.980] [info] latency measured for server 10153: 29354\n",
            "[2017-06-05 17:10:21.980] [info] new lowest latency server (id=10153) found with latency 29354\n",
            "[2017-06-05 17:10:21.980] [info] server selected: 10153\n",
            "[2017-06-05 17:10:21.980] [info] Server id: 10153\n",
            "serverid: 10153\n",
            "[2017-06-05 17:10:21.980] [info] Running TCP test suite\n",
            "[2017-06-05 17:10:21.980] [info] Running Speedtest against host:port kansas-city.speedtest.centurylink.net:8080\n",
            "[2017-06-05 17:10:21.980] [info] Resolving host in thread.\n",
            "[2017-06-05 17:10:21.981] [info] Resolved address 1: 205.171.29.26\n",
            "[2017-06-05 17:10:21.981] [info] Opening socket to '205.171.29.26'\n",
            "[2017-06-05 17:10:22.022] [info] Host kansas-city.speedtest.centurylink.net resolved to 205.171.29.26\n",
            "[2017-06-05 17:10:22.022] [info] Starting stage 1 of type 2\n",
            "[2017-06-05 17:10:22.520] [info] Ping 1: 27.37 ms (27.37ms avg, 0.00ms jitter)\n",
            "[2017-06-05 17:10:22.545] [info] Ping 2: 25.54 ms (25.54ms avg, 1.83ms jitter)\n",
            "[2017-06-05 17:10:22.570] [info] Ping 3: 24.90 ms (24.90ms avg, 1.24ms jitter)\n",
            "[2017-06-05 17:10:22.599] [info] Ping 4: 28.21 ms (24.90ms avg, 1.93ms jitter)\n",
            "[2017-06-05 17:10:22.625] [info] Ping 5: 25.89 ms (24.90ms avg, 2.02ms jitter)\n",
            "[2017-06-05 17:10:22.625] [info] Final Ping: 24.90 ms\n",
            "[2017-06-05 17:10:22.625] [info] Stage 1 completed\n",
            "[2017-06-05 17:10:22.625] [info] Current stage type: 2\n",
            "latency: 24\n",
            "[2017-06-05 17:10:22.625] [info] Starting stage 2 of type 4\n",
            "[2017-06-05 17:10:23.227] [info] Upload test: Received 4112 bytes\t0% complete\t138848 bytes/sec avg\n",
            "[2017-06-05 17:10:23.345] [info] Upload test: Received 33883 bytes\t1% complete\t258286 bytes/sec avg\n",
            "[2017-06-05 17:10:37.176] [info] Upload test: Received 138655 bytes\t93% complete\t1313393 bytes/sec avg\n",
            "[2017-06-05 17:10:37.327] [info] Upload test: Received 199716 bytes\t94% complete\t1313893 bytes/sec avg\n",
            "[2017-06-05 17:10:37.344] [info] Upload test: Received 229411 bytes\t94% complete\t1314904 bytes/sec avg\n",
            "[2017-06-05 17:10:37.529] [info] Upload test: Received 166386 bytes\t96% complete\t1314998 bytes/sec avg\n",
            "[2017-06-05 17:10:37.579] [info] Upload test: Received 90780 bytes\t96% complete\t1315198 bytes/sec avg\n",
            "[2017-06-05 17:10:37.748] [info] Upload test: Received 166386 bytes\t97% complete\t1315440 bytes/sec avg\n",
            "[2017-06-05 17:10:38.134] [info] Upload test: Received 275293 bytes\t100% complete\t1316296 bytes/sec avg\n",
            "[2017-06-05 17:10:38.201] [info] Current stage type: 4\n",
            "upload: 10532\n",
            "[2017-06-05 17:10:38.202] [info] Starting stage 3 of type 3\n",
            "[2017-06-05 17:10:38.403] [info] Download test: Received 4096 bytes\t0% complete\t1550927 bytes/sec avg\n",
            "[2017-06-05 17:10:38.437] [info] Download test: Received 29560 bytes\t0% complete\t928620 bytes/sec avg\n",
            "[2017-06-05 17:10:38.471] [info] Download test: Received 30304 bytes\t0% complete\t913949 bytes/sec avg\n",
            "[2017-06-05 17:10:52.922] [info] Download test: Received 747168 bytes\t99% complete\t43696134 bytes/sec avg\n",
            "[2017-06-05 17:10:52.939] [info] Download test: Received 767440 bytes\t99% complete\t43696213 bytes/sec avg\n",
            "[2017-06-05 17:10:52.955] [info] Download test: Received 1072968 bytes\t99% complete\t43696587 bytes/sec avg\n",
            "[2017-06-05 17:10:52.973] [info] Download test: Received 377928 bytes\t99% complete\t43696272 bytes/sec avg\n",
            "[2017-06-05 17:10:52.989] [info] Download test: Received 858664 bytes\t99% complete\t43696424 bytes/sec avg\n",
            "[2017-06-05 17:10:53.006] [info] Download test: Received 757304 bytes\t99% complete\t43696479 bytes/sec avg\n",
            "[2017-06-05 17:10:53.023] [info] Download test: Received 645808 bytes\t99% complete\t43696462 bytes/sec avg\n",
            "[2017-06-05 17:10:53.040] [info] Download test: Received 744272 bytes\t99% complete\t43696513 bytes/sec avg\n",
            "[2017-06-05 17:10:53.057] [info] Download test: Received 732688 bytes\t100% complete\t43696556 bytes/sec avg\n",
            "[2017-06-05 17:10:53.074] [info] Download test: Received 738480 bytes\t100% complete\t43696602 bytes/sec avg\n",
            "[2017-06-05 17:10:53.092] [info] Download test: Received 920928 bytes\t100% complete\t43696675 bytes/sec avg\n",
            "[2017-06-05 17:10:53.109] [info] Download test: Received 764544 bytes\t100% complete\t43696709 bytes/sec avg\n",
            "[2017-06-05 17:10:53.126] [info] Current stage type: 3\n",
            "download: 349573\n",
            "[2017-06-05 17:10:53.126] [info] final result - serverid: 10153 ping: 24 download: 349573 upload: 10532\n",
            "[2017-06-05 17:10:53.126] [info] total bytes downloaded: 600012968\n",
            "[2017-06-05 17:10:53.126] [info] total download stage duration: 14724884us\n",
            "[2017-06-05 17:10:53.126] [info] total bytes uploaded: 18479429\n",
            "[2017-06-05 17:10:53.126] [info] total upload stage duration: 15003460us\n",
            "[2017-06-05 17:10:53.127] [info] [http] == Info:   Trying 72.21.92.82...\n",
            "\n",
            "[2017-06-05 17:10:53.127] [info] [http] == Info: TCP_NODELAY set\n",
            "\n",
            "[2017-06-05 17:10:53.280] [info] [http] == Info: Connected to www.speedtest.net (72.21.92.82) port 80 (#0)\n",
            "\n",
            "[2017-06-05 17:10:53.280] [info] [http] == Info: upload completely sent off: 226 out of 226 bytes\n",
            "\n",
            "[2017-06-05 17:10:53.548] [info] [http] == Info: Connection #0 to host www.speedtest.net left intact\n",
            "\n",
            "[2017-06-05 17:10:53.548] [info] HTTP request (effective url: http://www.speedtest.net/api/embed/api.php) completed with response code 200\n"
    ]
}
