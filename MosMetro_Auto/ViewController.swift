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

    let MosMetro = MosMetroAPI()

    //Text
    @IBOutlet weak var WifiName: UILabel!
    @IBOutlet weak var InternetState: UILabel!
    @IBOutlet weak var DebugText: UITextView!


    // Button
    @IBAction func GetSSID(sender: AnyObject) {
        WifiName.text = MosMetro.getSSID()
        if (MosMetro.inMetro()) {
            DebugLog("Вы в метро!")
        }
    }

    @IBAction func Connect(sender: UIButton) {
        DebugLog("# Начало подключения к интернету:")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let bool = self.connectInternet()
            dispatch_async(dispatch_get_main_queue()) {
                if (bool) {
                    self.DebugLog("# Подключение выполнено")
                } else {
                    self.DebugLog("# Подключение НЕ выполнено")
                }
            }
        }
    }

    @IBAction func Check(sender: UIButton) {
        DebugLog("# Проверка интернета")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let result = self.MosMetro.checkInternet()
            dispatch_async(dispatch_get_main_queue()) {
                if (result) {
                    self.InternetState.text = "Есть"
                    self.DebugLog("# Подключение к интрнету: Есть")
                } else {
                    self.InternetState.text = "Нет"
                    self.DebugLog("# Подключение к интрнету: Нет")
                }
            }
        }
    }

    func DebugLog(newLine: AnyObject) {
        print(newLine)
        let text = "\n\(String(newLine))"
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.DebugText.text = self.DebugText.text.stringByAppendingString(text)
            if (self.DebugText.text.characters.count > 0) {
                let range = NSMakeRange(self.DebugText.text.characters.count - 1, 1);
                self.DebugText.scrollRangeToVisible(range);
            }
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

        DebugLog("> Подключение к сети " + MosMetro.getSSID());
        DebugLog(">> Проверка доступа в интернет");
        let connected = MosMetro.checkInternet();

        if (connected) {
            DebugLog("<< Уже есть");
            //return true; //Раз есть то смысла нет
        } else  {
            DebugLog("<< Интернета нет");
        }


        DebugLog(">>> Получение начального перенаправления");
        if let url = NSURL(string: MosMetro.loginURL) {
            do {
            let contents = try NSString(contentsOfURL: url, usedEncoding: nil)
            if (contents != "") {

                let findRedirect = matchesForRegexInText("URL=([?=&\\da-z\\.-:\\.\\/\\w \\.-]*)", text: contents as String)

                let rawUrlRedirect = String(findRedirect)
                if rawUrlRedirect != "[]" {
                    let rangeURL = Range(rawUrlRedirect.startIndex.advancedBy(6)..<rawUrlRedirect.endIndex.advancedBy(-2))
                    RedirectURL = rawUrlRedirect[rangeURL]

                } else {
                    DebugLog("<<< Ошибка: перенаправление не найдено")
                    DebugLog("<<< Нет ссылки")
                    return false
                }

            } else {
                DebugLog("<<< Ошибка: перенаправление не найдено")
                DebugLog("<<< Нет контента")
                return false
                }
            } catch {
                DebugLog("[Error:1] Эксепшон!!")
                return false
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
        
        let task = session.dataTaskWithRequest(request) {
            (let data, let response, let error) in

            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                return
            }

            let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            self.DebugLog(dataString!)

            self.DebugLog(">> Проверка доступа в интернет");
            if (self.MosMetro.checkInternet()) {
                self.DebugLog("<< Соединение успешно установлено :3");
            } else {
                self.DebugLog("<< Ошибка: доступ в интернет отсутствует");
            }
        }

        task.resume()

        return true;
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        WifiName.text = MosMetro.getSSID()
        
        if (MosMetro.inMetro()) {
            DebugLog("> Проверка интернета...")
            if (MosMetro.checkInternet()) {
                InternetState.text = "Есть"
                DebugLog("> Есть")
            } else {
                InternetState.text = "Нет"
                DebugLog("> Нет")
                DebugLog("> Произвожу подключение")
                connectInternet()
            }
        } else {
            DebugLog("Вы не в метро, или проверьте настройки wi-fi")
        }

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
