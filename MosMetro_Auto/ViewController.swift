//
//  ViewController.swift
//  MosMetro_Auto
//
//  Created by Anton Palgunov on 25.04.16.
//  Copyright © 2016 toxblh. All rights reserved.
//

import UIKit
import SystemConfiguration.CaptiveNetwork

//import <NetworkExtension/NetworkExtension.h>

class ViewController: UIViewController {

    //Text
    @IBOutlet weak var WifiName: UILabel!
    @IBOutlet weak var InternetState: UILabel!
    @IBOutlet weak var DebugText: UITextView!


    // Button
    @IBAction func GetSSID(sender: AnyObject) {
        let alertController = UIAlertController(title: "MosMetro_Auto", message:
            "Get SSID", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default,handler: nil))

        self.presentViewController(alertController, animated: true, completion: nil)

        let NameWifi = fetchSSIDInfo()
        WifiName.text = NameWifi
    }

    @IBAction func Connect(sender: UIButton) {
        DebugLog("Connect to Internet")
        setNotification("Успешное подключение к интернету", action: "Какой-то экшон", time: 10)
        connectInternet()
    }

    @IBAction func TryConnect(sender: UIButton) {
        if (tryConnect("https://www.ya.ru")) {
            InternetState.text = "Есть"
        } else {
            InternetState.text = "Нет"
        }
    }

    func fetchSSIDInfo() ->  String {
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

    func tryConnect(address: String) -> Bool {
        if let url = NSURL(string: address) {
            do {
                let contents = try NSString(contentsOfURL: url, usedEncoding: nil)
                print(contents)
                if (contents != "") {
                    DebugLog("Есть подключение к интернету")
                    return true
                }
                else {
                    DebugLog("Нет подключения к интернету")
                    return false
                }
            } catch {
                // contents could not be loaded
            }
        } else {
            // the URL was bad!
        }

        return false
    }


    func DebugLog(newLine: NSString) {
        let text = "\n\(newLine as String)"
        DebugText.text = DebugText.text.stringByAppendingString(text)
    }

    func connectInternet() {
        print("Connect")

        if (tryConnect("http://1.1.1.1/login.html")) {

        }
        /*
         // Запрашиваем страницу с кнопкой авторизации

         page_auth = requests.get(url_auth, headers=headers,
         cookies=page_vmetro.cookies,
         verify=False)
         headers.update({'referer': page_auth.url})

         // Парсим поля скрытой формы

         parser = FormInputParser()
         parser.feed(re.search("<body>.*?</body>",
         page_auth.content, re.DOTALL).group(0))

         // Отправляем полученную форму

         requests.post(url_auth, data=post_data,
         cookies=page_auth.cookies,
         headers=headers, verify=False)
         */

    }

    func main() {
        let now = NSDate()
        print(now)
        /*
         # "Пингуем" роутер
         if tryConnect("http://1.1.1.1/login.html"):
         for counter in range(3):
         try:
         # Получаем перенаправление
         page_vmetro = requests.get('http://vmet.ro', verify=False)
         headers.update({'referer': page_vmetro.url})

         # Вытаскиваем назначение редиректа
         url_auth = re.search('https?:[^\"]*', page_vmetro.text).group(0)

         except requests.exceptions.ConnectionError:
         if counter == 0:
         print("Already connected")
         else:
         print("Connected")
         break

         try:
         print("Connecting...")
         connect(url_auth)
         except requests.exceptions.ConnectionError:
         print("Connection failed")

         else:
         print("Wrong network")
         */
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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
