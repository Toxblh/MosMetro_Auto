//
//  MosMetroAPI.swift
//  MosMetro_Auto
//
//  Created by Anton Palgunov on 29.04.16.
//  Copyright © 2016 toxblh. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork

class MosMetroAPI {
    func getSSID() ->  String {
        var currentSSID = "";
        let interfaces:CFArray! = CNCopySupportedInterfaces()
        for i in 0..<CFArrayGetCount(interfaces){
            let interfaceName: UnsafePointer<Void>
                =  CFArrayGetValueAtIndex(interfaces, i)
            let rec = unsafeBitCast(interfaceName, AnyObject.self)
            let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)")
            if unsafeInterfaceData != nil {
                let interfaceData = unsafeInterfaceData! as Dictionary!
                currentSSID = interfaceData["SSID"] as! String
            } else {
                currentSSID = "Not connected wi-fi"
            }
        }
        return currentSSID
    }
}
