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
    let SSID_Metro2 = "AURA"
    let loginURL = "http://wi-fi.ru"
    let testURL = "https://ya.ru"
    
    func getSSID() ->  String {
        var currentSSID = ""
        if let interfaces:CFArray = CNCopySupportedInterfaces() {
            for i in 0..<CFArrayGetCount(interfaces){
                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interfaces, i)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString)
                if unsafeInterfaceData != nil {
                    let interfaceData = unsafeInterfaceData! as Dictionary!
                    for dictData in interfaceData! {
                        if dictData.key as! String == "SSID" {
                            currentSSID = dictData.value as! String
                        }
                    }
                } else {
                    currentSSID = "Not connected wi-fi"
                }
            }
        }
        return currentSSID
    }
    
    func checkInternet() -> Bool {
        if let url = URL(string: testURL) {
            do {
                let contents = try NSString(contentsOf: url, usedEncoding: nil)
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
        if (getSSID() == SSID_Metro || getSSID() == SSID_Metro2) {
            return true
        } else {
            return false
        }
    }
    
    func connect() -> Bool {
        var RedirectURL = ""
        
        if let url = URL(string: loginURL) {
            do {
                let contents = try NSString(contentsOf: url, usedEncoding: nil)
                if (contents != "") {
                    
                    let findRedirect = matchesForRegexInText("URL=([?=&\\da-z\\.-:\\.\\/\\w \\.-]*)", text: contents as String)
                    
                    let rawUrlRedirect = String(describing: findRedirect)
                    if rawUrlRedirect != "[]" {
                        let rangeURL = Range(rawUrlRedirect.characters.index(rawUrlRedirect.startIndex, offsetBy: 6)..<rawUrlRedirect.characters.index(rawUrlRedirect.endIndex, offsetBy: -2))
                        RedirectURL = String(rawUrlRedirect[rangeURL])
                        
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
        
        let tutorialsURL = URL(string: RedirectURL)
        let htmlData: Data = try! Data(contentsOf: tutorialsURL!)
        let input = NSString(data: htmlData, encoding: String.Encoding.utf8.rawValue)
        
        let findCsrfSign = matchesForRegexInText("<input type=\"hidden\" name=\"csrf\\.sign\" value=\"[0-9a-z]*\"\\/>", text: input! as String)
        let rawCsrfSign = String(describing: findCsrfSign)
        let rangeCsrfSign = rawCsrfSign.characters.index(rawCsrfSign.startIndex, offsetBy: 52)..<rawCsrfSign.characters.index(rawCsrfSign.endIndex, offsetBy: -6)
        let csrfSign = rawCsrfSign[rangeCsrfSign]
        let findCsrfTs = matchesForRegexInText("<input type=\"hidden\" name=\"csrf\\.ts\" value=\"[0-9a-z]*\"\\/>", text: input! as String)
        let rawCsrfTs = String(describing: findCsrfTs)
        let rangeCsrfTs = rawCsrfTs.characters.index(rawCsrfTs.startIndex, offsetBy: 50)..<rawCsrfTs.characters.index(rawCsrfTs.endIndex, offsetBy: -6)
        let csrfTs = rawCsrfTs[rangeCsrfTs]
        
        let url:URL = URL(string: RedirectURL)!
        let session = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        let paramString = "promogoto=&IDButton=Confirm&csrf.sign="+csrfSign+"&csrf.ts="+csrfTs
        request.httpBody = paramString.data(using: String.Encoding.utf8)
        
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, error) in
            
            guard let _:Data = data, let _:URLResponse = response, error == nil else {
                return
            }
        }) 
        
        task.resume()
        
        return true;
    }
    
    func matchesForRegexInText(_ regex: String!, text: String!) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matches(in: text,
                                                options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch  {
            return []
        }
    }
}
