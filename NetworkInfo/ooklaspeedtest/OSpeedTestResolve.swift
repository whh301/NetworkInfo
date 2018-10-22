

class OSpeedTestResolve {
    public let TAG:String = "OSpeedTestResolve"
    var myactivity:OSpeedViewController;
    var commandHelper:OSpeedCommandHelper;
    var editHelper:OSpeedEditConfigHelper;
    public static let settingUrl:String =
            "http://www.speedtest.net/speedtest-config.php"
    private static let urlTimeout:Int = 3000;

    init(a : OSpeedViewController, c : OSpeedCommandHelper) {
        myactivity = a
        commandHelper = c
        editHelper = commandHelper.editHelper
    }

    func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    public func resolveServersFromConfigUrl(searchParms: String, append: Bool) ->Bool {
        Log.d(tag: TAG, string: "resolveServersFromConfig")
        var retval = false
        var settings = ""
        do {
            let tgtUrl:URL = URL(string: "\(Servers.serversUrl)\(searchParms)")!
            let request: NSMutableURLRequest = NSMutableURLRequest(url: tgtUrl)
            request.allowsCellularAccess = true
            request.httpMethod = "GET"
            let response: AutoreleasingUnsafeMutablePointer<URLResponse?>? = nil

            let dataVal = try NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: response)
            
            print(response ?? "")
            settings = String(data: dataVal, encoding: String.Encoding.utf8)!
            print(settings)
            
            Log.v(tag: TAG,string: settings);

            if (editHelper.servers == nil || !append) {
                editHelper.servers = NSMutableArray()
            }

            let pattern = "(?s)(?<=\\[\n).*(?=\n\\])"
            let servRst = matches(for: pattern, in: settings)
            if servRst.count > 0 {
                // Split the string with ","
                let srvArray = servRst[0].split(separator: Character.init("}"))

                var id = 0
                var host = ""
                var name = ""
                var country = ""
                var sponsor = ""

                for srvStr in srvArray {
                    let paramList = srvStr.split(separator: "\n")
                    for paramStr in paramList {
                        let realStr = String(paramStr)
                        if realStr != "{" && realStr != "}" {
                            if realStr.contains("serverid") {
                                id = Int(String(realStr.split(separator: "\"")[1]))!
                            } else if realStr.contains("host") || realStr.contains("url") {
                                host = String(realStr.split(separator: "\"")[1])
                            } else if realStr.contains("name") {
                                name = String(realStr.split(separator: "\"")[1])
                            } else if (realStr.contains("country")) {
                                country = String(realStr.split(separator: "\"")[1])
                            } else if realStr.contains("sponsor") {
                                sponsor = String(realStr.split(separator: "\"")[1])
                            }
                        }
                    }
                    let newServer = Servers(i: id, h: host, n: name, c: country, s: sponsor)
                    editHelper.servers.add(newServer)
                }
            }

            retval = true
        } catch let error {
            Log.e(tag: TAG, string: "MalformedURLException: \(error.localizedDescription)")
        }
            
        if (retval) {
            writeServerToListFile()
        }
        
        return retval;
    }

    private func writeServerToListFile() {
        var availableServeList = ""
        for i in 0..<editHelper.servers.count {
            let s = editHelper.servers[i] as! Servers
            availableServeList += "IDX=\(i),ID=\(s.id),HOST=\(s.host) ,NAME=\(s.name),COUNTRY=\(s.country),SPONSOR=\(s.sponsor)\n"
        }

        Log.WriteToFileQuick(filename: AdbService.SPEED_SERVER_LIST, data: availableServeList, append: false);
    }

    public func findServerInList(id: Int) -> Bool {
        Log.d(tag: TAG, string: "findServerInList")
        for i in 0..<editHelper.servers.count {
            if ((editHelper.servers[i] as! Servers).id == id) {
                Log.d(tag: TAG, string: "findServerInList Success");
                return true
            }
        }
        return false
    }
}
