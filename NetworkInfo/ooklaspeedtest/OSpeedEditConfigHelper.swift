
public class Servers {
    
    public static let serversUrl:String =
        //                "http://c.speedtest.net/speedtest-servers-static.php";
    "https://www.speedtest.net/api/embed/spirent/config";
    
    
    public var id:Int!
    public var host:String!
    public var name:String!
    public var country:String!
    public var sponsor:String!
    
    public init(i:Int, h:String, p:String) {
        id = i;
        host = h + ":" + p;
        name = "";
        sponsor = "";
        country = "";
    }
    
    public init (s: Servers) {
        id = s.id;
        host = s.host;
        name = s.name;
        sponsor = s.sponsor;
        country = s.country;
    }
    
    public init (i: Int, h:String, n:String, c:String, s:String) {
        id = i;
        host = h;
        name = n;
        sponsor = s;
        country = c;
    }
}

/**
 * Created by ssubbarao on 8/25/16.
 */
public class OSpeedEditConfigHelper {
    public static let TAG:String = "OSTEditConfigHelper"
    public static let APP_PATH:String = "/data/data/com.spirent.networkanalyzer/"
    public static let LAST_CONFIG_FILE:String = APP_PATH + "OSTConfig.txt"
    public static let SCHEDULED_CONFIG_FILE:String = APP_PATH + "OSTScheduledTestConfig.txt"
    public static let SCHEDULED_LOG_FILE:String = APP_PATH + "ost_scheduled_log.txt"
    public static let SAVE_LOG_FILE:String = APP_PATH + "ost_save_log.txt"
    public static let OOKLA_SETTINGS_FILE:String = APP_PATH + "settings.txt"
    public static let OOKLA_BACKUP_SETTINGS_FILE:String = APP_PATH + "backup_settings.txt"
    let DEFAULT_OST_URL = "10153";//"10153:kansas-city.speedtest.centurylink.net:8080;Centurylink;US;Centurylink;38.93;-94.66";

    var License:NSMutableArray!
    var header:String!
    var customer:String!
    var licensekey:String!
    var threadnum:Int!
    var uploadfirst:Int!
    var testlength:Int!
    var latencytestlength:Int!
    var packetlength:Int!
    var tracelevel:Int!
    var apiurl:String!
    var servers:NSMutableArray!

    var testDuration:Int!
    var override_server_id:Int!
    var override_server_sponsor:Int!

    var scheduled_time:String

    var fakeLicensekey:String

    enum OSTConfigEnum: Int {
        case OVERRIDESERVER
        case SCHEDULETIME
        case LOGLEVEL
        case LASTENUM
        
        /// String representation of the address family.
        public func toString() -> String {
            switch (self) {
                case .OVERRIDESERVER:
                    return "OVERRIDESERVER"
                case .SCHEDULETIME:
                    return "SCHEDULETIME"
                case .LOGLEVEL:
                    return "LOGLEVEL"
                case .LASTENUM:
                    return "LOGLEVEL"
            }
        }
    }

    public init() {
        testlength = 10
        latencytestlength = 10
        servers = nil
        override_server_id = 0
        override_server_sponsor = 0
        scheduled_time = ""
        testDuration = latencytestlength + 3 * testlength + 20
        fakeLicensekey = "0bc5dc245c3d2280-Cdb5cd12df4439174-c1e684cc76d84044"
    }

    public func getConfig() -> String {
        var ret = "";

        if (override_server_id != 0) {
            ret = "\(OSTConfigEnum.OVERRIDESERVER)=\(override_server_id);\(override_server_sponsor),\(OSTConfigEnum.SCHEDULETIME)=\(scheduled_time),\(OSTConfigEnum.LOGLEVEL)=\(Log.getLogLevel()),"
        }

        return ret;
    }

    public func loadLastConfig(filename:String) -> String {
        Log.d(tag: OSpeedEditConfigHelper.TAG, string: "loadLastConfig")
        let config = Log.readFile(filename: filename)
        return parseConfig(config: config)
    }

    public func parseConfig(config: String) -> String {
        if (config.isEmpty) {
            return "";
        }
        
        let fillconfig = config.split(separator: ",")
        Log.i(tag: OSpeedEditConfigHelper.TAG, string: config)
        for i in 0..<fillconfig.count {
            if (fillconfig[i].contains("=")) {
                let temp = fillconfig[i].split(separator: "=")
                var value = ""
                var param = String(temp[0])
                if (temp.count > 1) {
                    value = String(temp[1])
                }
                
                if (value.isEmpty) {
                    continue
                }
                
                Log.d7(tag: OSpeedEditConfigHelper.TAG, string: param + ":" + value)
                
                if (param == OSTConfigEnum.OVERRIDESERVER.toString()) {
                    let parts = value.split(separator: ";")
                    override_server_id = Int(String(parts[0]))
                    if (parts.count > 1) {
                        override_server_sponsor = Int(String(parts[1]))
                    } else {
                        override_server_sponsor = 0
                    }
                    
                    Log.i(tag: OSpeedEditConfigHelper.TAG,string: "OverrideServerId:\(override_server_id), OverrideServerSponsor: \(override_server_sponsor)")
                } else if (param == OSTConfigEnum.SCHEDULETIME.toString()) {
                    if (value.contains("true")) {
                        scheduled_time = value
                    }
                } else if (param == OSTConfigEnum.LOGLEVEL.toString()) {
                    Log.setLogLevel(level: Int(value)!)
                }
            }
        }

        return config;
    }

    public func getServerDetails(id: Int) -> Servers? {
        if (servers != nil) {
            for i in 0..<servers.count {
                let s = servers[i] as! Servers
                if (s.id == id) {
                    return s;
                }
            }
        }
        
        return nil
    }
}
