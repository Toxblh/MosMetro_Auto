//
//  ViewController.swift
//  MosMetro_Auto
//
//  Created by Anton Palgunov on 25.04.16.
//  Copyright © 2016 toxblh. All rights reserved.
//
import UIKit
import SystemConfiguration.CaptiveNetwork

class ViewController: UIViewController {

    let SSID_Metro = "MosMetro_Free"
    let loginURL = "http://wi-fi.ru"

    //Text
    @IBOutlet weak var WifiName: UILabel!
    @IBOutlet weak var InternetState: UILabel!
    @IBOutlet weak var DebugText: UITextView!


    // Button
    @IBAction func GetSSID(sender: AnyObject) {
//        let NameWifi = getSSID()
//        WifiName.text = NameWifi
//        if (NameWifi ==  SSID_Metro) {
//            DebugLog("Вы в метро!")
//        }

    }

    @IBAction func Connect(sender: UIButton) {
        DebugLog("Connect to Internet")
        setNotification("Успешное подключение к интернету", action: "Какой-то экшон", time: 10)
        connectInternet()
    }

    @IBAction func Check(sender: UIButton) {
        if (checkInternet()) {
            InternetState.text = "Есть"
        } else {
            InternetState.text = "Нет"
        }
    }


    func DebugLog(newLine: AnyObject) {
        print(newLine)
        let text = "\n\(String(newLine))"
        dispatch_async(dispatch_get_main_queue(), {
            self.DebugText.text = self.DebugText.text.stringByAppendingString(text)
        })
    }

    func httpRequest(url: String, completion: (html: NSString?, headers: NSObject?, code: Int?,error: String?)->()) {
        let session = NSURLSession.sharedSession()
        let getUrl = NSURL(string: url)

        let task = session.dataTaskWithURL(getUrl!){
            (data, response, error) -> Void in

            if error != nil {
                completion(html: nil, headers: nil, code: nil, error: (error!.localizedDescription) as String)
            } else {
                let result = NSString(data: data!, encoding:
                    NSUTF8StringEncoding)!

                if let httpUrlResponse = response as? NSHTTPURLResponse
                {
                    if error != nil {
                        self.DebugLog("Error Occurred: \(error!.localizedDescription)")
                    } else {
                        let headers = httpUrlResponse.allHeaderFields
                        let code = httpUrlResponse.statusCode
                        completion(html: result, headers: headers, code: code, error: nil)
                    }
                }
            }
        }
        
        task.resume()
    }
    
    func DLog(html: NSString?, head: NSObject?, code: Int?, error: String?) {
        if error == nil {
            DebugLog(code!);
            DebugLog(head!);
            DebugLog(html!);
        } else {
            DebugLog(error!);
        }
        
    }
    
    func matchesForRegexInText(regex: String!, text: String!) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matchesInString(text,
                                                options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substringWithRange($0.range)}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    func connectInternet() -> Bool {
        var RedirectURL = ""
        print("Connect")

        //DebugLog("> Подключение к сети " + getSSID());
        DebugLog(">> Проверка доступа в интернет");
        let connected = checkInternet();
        
        if (connected) {
            DebugLog("<< Уже есть");
            //return true; //Раз есть то смысла нет
        } else  {
            DebugLog("<< Интернета нет");
        }


        DebugLog(">>> Получение начального перенаправления");
        if let url = NSURL(string: loginURL) {
            do {
            let contents = try NSString(contentsOfURL: url, usedEncoding: nil)
            if (contents != "") {
                DebugLog(contents)
                
                let findRedirect = matchesForRegexInText("URL=([?=&\\da-z\\.-:\\.\\/\\w \\.-]*)", text: contents as String)
                DebugLog(findRedirect)
                
                    let rawUrlRedirect = String(findRedirect)
                    if rawUrlRedirect != "[]" {
                        let rangeURL = Range(rawUrlRedirect.startIndex.advancedBy(6)..<rawUrlRedirect.endIndex.advancedBy(-2))
                        RedirectURL = rawUrlRedirect[rangeURL]
                        DebugLog(RedirectURL)
                    } else {
                        DebugLog("<<< Ошибка: перенаправление не найдено")
                        DebugLog("^<<Нет ссылки")
                        return false
                }
            } else {
                DebugLog("<<< Ошибка: перенаправление не найдено")
                DebugLog("^<<Нет контента")
                //return false
                }
            } catch {
                DebugLog("[Error:1] Эксепшон!!")
                //return false
            }
        }
        

        DebugLog(">>> Получение страницы авторизации");
        
        let tutorialsURL = NSURL(string: RedirectURL)
        let htmlData: NSData = NSData(contentsOfURL: tutorialsURL!)!
        let input = NSString(data: htmlData, encoding: NSUTF8StringEncoding)
        DebugLog(input!)
        
        let findCsrfSign = matchesForRegexInText("<input type=\"hidden\" name=\"csrf\\.sign\" value=\"[0-9a-z]*\"\\/>", text: input as! String)
        let rawCsrfSign = String(findCsrfSign)
        let rangeCsrfSign = rawCsrfSign.startIndex.advancedBy(52)..<rawCsrfSign.endIndex.advancedBy(-6)
        let csrfSign = rawCsrfSign[rangeCsrfSign]
        DebugLog(csrfSign)
        
        let findCsrfTs = matchesForRegexInText("<input type=\"hidden\" name=\"csrf\\.ts\" value=\"[0-9a-z]*\"\\/>", text: input as! String)
        let rawCsrfTs = String(findCsrfTs)
        let rangeCsrfTs = rawCsrfTs.startIndex.advancedBy(50)..<rawCsrfTs.endIndex.advancedBy(-6)
        let csrfTs = rawCsrfTs[rangeCsrfTs]
        DebugLog(csrfTs)
        
        
        DebugLog(">>> Отправка формы авторизации");
        
        let url:NSURL = NSURL(string: RedirectURL)!
        let session = NSURLSession.sharedSession()
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData
        
        let paramString = "promogoto=&IDButton=Confirm&csrf.sign="+csrfSign+"&csrf.ts="+csrfTs
        request.HTTPBody = paramString.dataUsingEncoding(NSUTF8StringEncoding)
        DebugLog(request)
        let task = session.dataTaskWithRequest(request) {
            (
            let data, let response, let error) in
            
            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                self.DebugLog("<<< Ошибка: сервер не ответил или вернул ошибку");
                return
            }
            
            let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            self.DebugLog(dataString!)
            
            self.DebugLog(">> Проверка доступа в интернет");
            if (self.checkInternet()) {
                self.DebugLog("<< Соединение успешно установлено :3");
            } else {
                self.DebugLog("<< Ошибка: доступ в интернет отсутствует");
            }
        }
        
        task.resume()
        
        return false;
    }

    func data_request()
    {
        let url:NSURL = NSURL(string: "https://ya.ru")!
        let session = NSURLSession.sharedSession()

        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData

        let paramString = "data=Hello"
        request.HTTPBody = paramString.dataUsingEncoding(NSUTF8StringEncoding)

        let task = session.dataTaskWithRequest(request) {
            (
            let data, let response, let error) in

            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                print("error")
                return
            }

            let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print(dataString)

        }

        task.resume()
    }


//    func getSSID() ->  String {
//        var currentSSID = ""
//        if let interfaces:CFArray! = CNCopySupportedInterfaces() {
//            for i in 0..<CFArrayGetCount(interfaces){
//                let interfaceName: UnsafePointer<Void> = CFArrayGetValueAtIndex(interfaces, i)
//                let rec = unsafeBitCast(interfaceName, AnyObject.self)
//                let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)")
//                if unsafeInterfaceData != nil {
//                    let interfaceData = unsafeInterfaceData! as Dictionary!
//                    currentSSID = interfaceData["SSID"] as! String
//                }
//            }
//        }
//        return currentSSID
//        if let list = cmd.networkList where cmd.commandType == .FilterScanList {
//            var networks = [NEHotspotNetwork]()
//            for network in list {
//                if network.SSID.hasPrefix("BTVNET") {
//                    network.setPassword("12345678")
//                    network.setConfidence(.High)
//                    networks.append(network)
//                }
//            }
//            let response = cmd.createResponse(.Success)
//            response.setNetworkList(networks)  
//            response.deliver()  
//        }
//        
//        
//        hotspotNetwork = NEHotspotHelper supportedNetworkInterfaces
//            NSString ssid = hotspotNetwork.SSID;
//            NSString bssid = hotspotNetwork.BSSID;
//            BOOL secure = hotspotNetwork.secure;
//            BOOL autoJoined = hotspotNetwork.autoJoined;
//            double signalStrength = hotspotNetwork.signalStrength;
//
//        return ""
//    }

    func checkInternet() -> Bool {

        let testURL = "https://www.ya.ru"

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

            }
        } else {

        }

        return false
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (checkInternet()) {
            InternetState.text = "Есть"
        } else {
            InternetState.text = "Нет"
        }
        
//        let NameWifi = getSSID()
//        WifiName.text = NameWifi
//        if (NameWifi ==  SSID_Metro) {
//            DebugLog("Вы в метро!")
//        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setNotification(body: String, action: String, time: NSTimeInterval) {
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)

        guard let settings = UIApplication.sharedApplication().currentUserNotificationSettings() else { return }

        if settings.types == .None {
            let ac = UIAlertController(title: "Нет доступа", message: "Ты не дал мне доступ к уведомлениям, поэтому я не смогу тебе сообщить если, что-то сломалось", preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(ac, animated: true, completion: nil)
            return
        }

        let notification = UILocalNotification()
        notification.fireDate = NSDate(timeIntervalSinceNow: time)
        notification.alertBody = body
        notification.alertAction = action
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.userInfo = ["CustomField1": "w00t"]
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }

    func viewAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default,handler: nil))

        self.presentViewController(alertController, animated: true, completion: nil)
    }

}
