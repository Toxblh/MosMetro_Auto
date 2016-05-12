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
    
    let SSID_Metro = "MosMetro_Free"
    let loginURL = "http://wi-fi.ru"
    let testURL = "https://ya.ru"
    
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
    
    func checkInternet() -> Bool {
        if let url = NSURL(string: testURL) {
            do {
                let contents = try NSString(contentsOfURL: url, usedEncoding: nil)
                if (contents != "") {
                    return true
                }
                else {
                    return false
                }
            } catch {
                return false
            }
        } else {
            return false
        }
    }
    
    func inMetro() -> Bool {
        if (getSSID() == SSID_Metro) {
            return true
        } else {
            return false
        }
    }
    
    func connect() -> Bool {
        var RedirectURL = ""
        
        if let url = NSURL(string: loginURL) {
            do {
                let contents = try NSString(contentsOfURL: url, usedEncoding: nil)
                if (contents != "") {
                    
                    let findRedirect = matchesForRegexInText("URL=([?=&\\da-z\\.-:\\.\\/\\w \\.-]*)", text: contents as String)
                    
                    let rawUrlRedirect = String(findRedirect)
                    if rawUrlRedirect != "[]" {
                        let rangeURL = Range(rawUrlRedirect.startIndex.advancedBy(6)..<rawUrlRedirect.endIndex.advancedBy(-2))
                        RedirectURL = rawUrlRedirect[rangeURL]
                        
                    } else {
                        return false
                    }
                    
                } else {
                    return false
                }
            } catch {
                return false
            }
        }
        
        let tutorialsURL = NSURL(string: RedirectURL)
        let htmlData: NSData = NSData(contentsOfURL: tutorialsURL!)!
        let input = NSString(data: htmlData, encoding: NSUTF8StringEncoding)
        
        let findCsrfSign = matchesForRegexInText("<input type=\"hidden\" name=\"csrf\\.sign\" value=\"[0-9a-z]*\"\\/>", text: input as! String)
        let rawCsrfSign = String(findCsrfSign)
        let rangeCsrfSign = rawCsrfSign.startIndex.advancedBy(52)..<rawCsrfSign.endIndex.advancedBy(-6)
        let csrfSign = rawCsrfSign[rangeCsrfSign]
        let findCsrfTs = matchesForRegexInText("<input type=\"hidden\" name=\"csrf\\.ts\" value=\"[0-9a-z]*\"\\/>", text: input as! String)
        let rawCsrfTs = String(findCsrfTs)
        let rangeCsrfTs = rawCsrfTs.startIndex.advancedBy(50)..<rawCsrfTs.endIndex.advancedBy(-6)
        let csrfTs = rawCsrfTs[rangeCsrfTs]
        
        let url:NSURL = NSURL(string: RedirectURL)!
        let session = NSURLSession.sharedSession()
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData
        
        let paramString = "promogoto=&IDButton=Confirm&csrf.sign="+csrfSign+"&csrf.ts="+csrfTs
        request.HTTPBody = paramString.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = session.dataTaskWithRequest(request) {
            (let data, let response, let error) in
            
            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                return
            }
        }
        
        task.resume()
        
        return true;
    }
    
    func matchesForRegexInText(regex: String!, text: String!) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matchesInString(text,
                                                options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substringWithRange($0.range)}
        } catch  {
            return []
        }
    }
}
