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
        let NameWifi = getSSID()
        WifiName.text = NameWifi
        if (NameWifi ==  SSID_Metro) {
            DebugLog("Вы в метро!")
        }

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


    func DebugLog(newLine: NSString) {
        let text = "\n\(newLine as String)"
        DebugText.text = DebugText.text.stringByAppendingString(text)
    }

    func httpRequest(completion: (html: NSString?, headers: NSObject? ,error: NSError?)->(), url: String) {
        let session = NSURLSession.sharedSession()
        let getUrl = NSURL(string: url)

        let task = session.dataTaskWithURL(getUrl!){
            (data, response, error) -> Void in

            if error != nil {
                print(error?.localizedDescription)
                completion(html: nil, headers: nil, error: error)
            } else {
                let result = NSString(data: data!, encoding:
                    NSUTF8StringEncoding)!

                if let httpUrlResponse = response as? NSHTTPURLResponse
                {
                    if error != nil {
                        print("Error Occurred: \(error!.localizedDescription)")
                    } else {
                        let headers = httpUrlResponse.allHeaderFields
                        print(headers.count)
                        print(headers["Server"])
                        print(headers.values)
                        print("\(headers)")
                        print(httpUrlResponse.statusCode)
                        
                        completion(html: result, headers: headers, error: nil)
                    }
                }
            }
        }
        
        task.resume()
    }


    func connectInternet() -> Bool {
        print("Connect")

        DebugLog("> Подключение к сети " + getSSID());
        DebugLog(">> Проверка доступа в интернет");
        var connected = checkInternet();
        
        if (connected) {
            DebugLog("<< Уже подключено");
        } else  {
            DebugLog("<< Ошибка: Сеть недоступна или не отвечает");
            return false;
        }


        DebugLog(">>> Получение начального перенаправления");
        if let url = NSURL(string: loginURL) {
            do {
            let contents = try NSString(contentsOfURL: url, usedEncoding: nil)
            if (contents != "") {
                DebugLog(contents)
                }
            } catch {
                
            }
        }
        
//        httpRequest({(html: NSString?, headers: NSObject?, error: NSError?) -> Void in
//            self.DebugLog(html!)
//        }, url: "https://ya.ru")
        
/*
        if (link = client.parseMetaRedirect()) {
            DebugLog(link);
        } else {
            DebugLog("<<< Ошибка: перенаправление не найдено");
            return false;
        }

        DebugLog(">>> Получение страницы авторизации");
        if (client.get(link)) {
            DebugLog(client.getPageContent().outerHtml());
        } else {
            DebugLog("<<< Ошибка: страница авторизации не получена");
            return false;
        }

        if (Elements forms = client.getPageContent().getElementsByTag("form")) {
            if (forms.size() > 1 && forms.last().attr("id").equals("sms-form")) {
                DebugLog("<<< Ошибка: устройство не зарегистрировано в сети");

                DebugLog("\nПожалуйста, зайдите на сайт http://wi-fi.ru и пройдите регистрацию, " +
                    "введя свой номер телефона в появившуюся форму для получения СМС с дальнейшими инструкциями. " +
                    "Это необходимо сделать только один раз, после чего приложение начнет нормально работать.");

                DebugLog("\nПримечание: Разработчик этого приложения не имеет никакого отношения к регистрации. " +
                    "Регистрацией, как и самой сетью, занимается компания МаксимаТелеком (http://maximatelecom.ru).");
                return false;
            }
            fields = Client.parseForm(forms.first());
        } else {
            DebugLog("<<< Ошибка: форма авторизации не найдена");
            return false;
        }

        DebugLog(">>> Отправка формы авторизации");
        if (client.post(link, fields)) {
            DebugLog(client.getPageContent().outerHtml());
        } else {
            DebugLog("<<< Ошибка: сервер не ответил или вернул ошибку");
            return false;
        }

        DebugLog(">> Проверка доступа в интернет");
        if (checkInternet()) {
            DebugLog("<< Соединение успешно установлено :3");
        } else {
            DebugLog("<< Ошибка: доступ в интернет отсутствует");
            return false;
        }*/
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


    func getSSID() ->  String {
        var currentSSID = ""
        if let interfaces:CFArray! = CNCopySupportedInterfaces() {
            for i in 0..<CFArrayGetCount(interfaces){
                let interfaceName: UnsafePointer<Void> = CFArrayGetValueAtIndex(interfaces, i)
                let rec = unsafeBitCast(interfaceName, AnyObject.self)
                let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)")
                if unsafeInterfaceData != nil {
                    let interfaceData = unsafeInterfaceData! as Dictionary!
                    currentSSID = interfaceData["SSID"] as! String
                }
            }
        }
        return currentSSID
    }

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
