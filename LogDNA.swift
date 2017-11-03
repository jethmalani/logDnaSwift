//
//  LogDNA.swift
//  TradingApp
//
//  Created by Nevin Jethmalani on 11/2/17.
//  Copyright © 2017 Nevin Jethmalani. All rights reserved.
//

import Cocoa
import Alamofire
import SwiftyJSON

class LogDNA: NSObject {
    
    var ingestionKey:String!
    var hostName:String!
    var appName:String!
    var deviceIpAddress:String!
    var deviceMacAddress:String?
    var verbose:Bool = false
    
    static var shared = LogDNA()
    
    class func setup(withIngestionKey ingestionKey:String, hostName:String, appName:String, includeNetworkData:Bool){
        self.shared.ingestionKey = ingestionKey
        self.shared.hostName = hostName
        self.shared.appName = appName
        
        if includeNetworkData == true {
            self.shared.deviceMacAddress = self.getMacAddress()
            self.shared.deviceIpAddress = self.getIPAddress()
        }
    }
    
    class func log(line:String, level:LogDNALevel, meta:[String:Any]){
        
        var headers: HTTPHeaders = [
            "content-type": "application/json; charset=UTF-8"
        ]
        
        guard let hostName = self.shared.hostName else {return}
        guard let credentials = self.shared.ingestionKey else {return}
        
        let credentialData = "\(credentials):\(credentials)".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        headers["Authorization"] = "Basic \(base64Credentials)"
        
        var parameters:Parameters = [String : Any]()
        
        var mainLine = [String:Any]()
        mainLine["line"] = line
        mainLine["app"] = self.shared.appName
        mainLine["level"] = level.value
        mainLine["meta"] = meta
        
        parameters["lines"]  = [mainLine]
        
        var url = "https://logs.logdna.com/logs/ingest?hostname=\(hostName)&now=\(Date().timeIntervalSince1970)"
        
        if let macAddressAvailable = self.shared.deviceMacAddress {
            url += "&mac=\(macAddressAvailable)"
        }
        
        if let ipAddressAvailable = self.shared.deviceIpAddress {
            url += "&ip=\(ipAddressAvailable)"
        }
        
        Alamofire.request(url, method: .post, parameters: parameters , encoding: JSONEncoding.default, headers: headers)
            .responseJSON { (response) in
            switch response.result {
            case .success(let value):
                if self.shared.verbose == true {
                    print ("return: \(value)")
                }
            case .failure(let error):
                if self.shared.verbose == true {
                    print ("error: \(error)")
                }
            }
        }
    }
    
    class func getIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    
                    if let name: String = String(cString: (interface?.ifa_name)!), name == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
    
    //These are all used for the mac address
    class func FindEthernetInterfaces() -> io_iterator_t? {
        
        let matchingDict = IOServiceMatching("IOEthernetInterface") as NSMutableDictionary
        matchingDict["IOPropertyMatch"] = [ "IOPrimaryInterface" : true]
        
        var matchingServices : io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &matchingServices) != KERN_SUCCESS {
            return nil
        }
        
        return matchingServices
    }
    
    class func getMACAddress(_ intfIterator : io_iterator_t) -> [UInt8]? {
        
        var macAddress : [UInt8]?
        
        var intfService = IOIteratorNext(intfIterator)
        while intfService != 0 {
            
            var controllerService : io_object_t = 0
            if IORegistryEntryGetParentEntry(intfService, "IOService", &controllerService) == KERN_SUCCESS {
                
                let dataUM = IORegistryEntryCreateCFProperty(controllerService, "IOMACAddress" as CFString, kCFAllocatorDefault, 0)
                if let data = dataUM?.takeRetainedValue() as? NSData {
                    macAddress = [0, 0, 0, 0, 0, 0]
                    data.getBytes(&macAddress!, length: macAddress!.count)
                }
                IOObjectRelease(controllerService)
            }
            
            IOObjectRelease(intfService)
            intfService = IOIteratorNext(intfIterator)
        }
        
        return macAddress
    }
    
    class func getMacAddress()-> String?{
        if let intfIterator = FindEthernetInterfaces() {
            if let macAddress = getMACAddress(intfIterator) {
                let macAddressAsString = macAddress.map( { String(format:"%02x", $0) } )
                    .joined(separator: ":")
                return macAddressAsString
            }
            IOObjectRelease(intfIterator)
        }
        return nil
    }
}

enum LogDNALevel {
    case debug
    case info
    case warn
    case error
    case fatal
    
    var value: String {
        switch self {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warn:
            return "WARN"
        case .error:
            return "ERROR"
        case .fatal:
            return "FATAL"
        }
    }
}
