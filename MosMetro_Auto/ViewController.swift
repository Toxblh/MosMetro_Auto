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
    @IBAction func GetSSID(_ sender: AnyObject) {
        WifiName.text = MosMetro.getSSID()
        if (MosMetro.inMetro()) {
            DebugLog("Вы в метро!" as AnyObject)
        }
    }

    @IBAction func Connect(_ sender: UIButton) {
        DebugLog("# Начало подключения к интернету:" as AnyObject)
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            let bool = self.connectInternet()
            DispatchQueue.main.async {
                if (bool) {
                    self.DebugLog("# Подключение выполнено" as AnyObject)
                } else {
                    self.DebugLog("# Подключение НЕ выполнено" as AnyObject)
                }
            }
        }
    }

    @IBAction func Check(_ sender: UIButton) {
        DebugLog("# Проверка интернета" as AnyObject)
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            let result = self.MosMetro.checkInternet()
            DispatchQueue.main.async {
                if (result) {
                    self.InternetState.text = "Есть"
                    self.DebugLog("# Подключение к интрнету: Есть" as AnyObject)
                } else {
                    self.InternetState.text = "Нет"
                    self.DebugLog("# Подключение к интрнету: Нет" as AnyObject)
                }
            }
        }
    }

    func DebugLog(_ newLine: AnyObject) {
        print(newLine)
        let text = "\n\(String(describing: newLine))"
        DispatchQueue.main.async(execute: { () -> Void in
            self.DebugText.text = self.DebugText.text + text
            if (self.DebugText.text.characters.count > 0) {
                let range = NSMakeRange(self.DebugText.text.characters.count - 1, 1);
                self.DebugText.scrollRangeToVisible(range);
            }
        })
    }

    func httpRequest(_ url: String, completion: @escaping (_ html: NSString?, _ headers: NSObject?, _ code: Int?,_ error: String?)->()) {
        let session = URLSession.shared
        let getUrl = URL(string: url)

        let task = session.dataTask(with: getUrl!, completionHandler: {
            (data, response, error) -> Void in

            if error != nil {
                completion(nil, nil, nil, (error!.localizedDescription) as String)
            } else {
                let result = NSString(data: data!, encoding:
                    String.Encoding.utf8.rawValue)!

                if let httpUrlResponse = response as? HTTPURLResponse
                {
                    if error != nil {
                        self.DebugLog("Error Occurred: \(error!.localizedDescription)" as AnyObject)
                    } else {
                        let headers = httpUrlResponse.allHeaderFields
                        let code = httpUrlResponse.statusCode
                        completion(result, headers as NSObject, code, nil)
                    }
                }
            }
        })

        task.resume()
    }

    func matchesForRegexInText(_ regex: String!, text: String!) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matches(in: text,
                                                options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    func connectInternet() -> Bool {
        var RedirectURL = ""

        DebugLog("> Подключение к сети " + MosMetro.getSSID() as AnyObject);
        DebugLog(">> Проверка доступа в интернет" as AnyObject);
        let connected = MosMetro.checkInternet();

        if (connected) {
            DebugLog("<< Уже есть" as AnyObject);
            //return true; //Раз есть то смысла нет
        } else  {
            DebugLog("<< Интернета нет" as AnyObject);
        }


        DebugLog(">>> Получение начального перенаправления" as AnyObject);
        if let url = URL(string: MosMetro.loginURL) {
            do {
            let contents = try NSString(contentsOf: url, usedEncoding: nil)
            if (contents != "") {

                let findRedirect = matchesForRegexInText("URL=([?=&\\da-z\\.-:\\.\\/\\w \\.-]*)", text: contents as String)

                let rawUrlRedirect = String(describing: findRedirect)
                if rawUrlRedirect != "[]" {
                    let rangeURL = Range(rawUrlRedirect.characters.index(rawUrlRedirect.startIndex, offsetBy: 6)..<rawUrlRedirect.characters.index(rawUrlRedirect.endIndex, offsetBy: -2))
                    RedirectURL = String(rawUrlRedirect[rangeURL])

                } else {
                    DebugLog("<<< Ошибка: перенаправление не найдено" as AnyObject)
                    DebugLog("<<< Нет ссылки" as AnyObject)
                    return false
                }

            } else {
                DebugLog("<<< Ошибка: перенаправление не найдено" as AnyObject)
                DebugLog("<<< Нет контента" as AnyObject)
                return false
                }
            } catch {
                DebugLog("[Error:1] Эксепшон!!" as AnyObject)
                return false
            }
        }


        DebugLog(">>> Получение страницы авторизации" as AnyObject);

        let tutorialsURL = URL(string: RedirectURL)
        let htmlData: Data = try! Data(contentsOf: tutorialsURL!)
        let input = NSString(data: htmlData, encoding: String.Encoding.utf8.rawValue)
        DebugLog(input!)

        let findCsrfSign = matchesForRegexInText("<input type=\"hidden\" name=\"csrf\\.sign\" value=\"[0-9a-z]*\"\\/>", text: input! as String)
        let rawCsrfSign = String(describing: findCsrfSign)
        let rangeCsrfSign = rawCsrfSign.characters.index(rawCsrfSign.startIndex, offsetBy: 52)..<rawCsrfSign.characters.index(rawCsrfSign.endIndex, offsetBy: -6)
        let csrfSign = rawCsrfSign[rangeCsrfSign]
        DebugLog(csrfSign as AnyObject)

        let findCsrfTs = matchesForRegexInText("<input type=\"hidden\" name=\"csrf\\.ts\" value=\"[0-9a-z]*\"\\/>", text: input! as String)
        let rawCsrfTs = String(describing: findCsrfTs)
        let rangeCsrfTs = rawCsrfTs.characters.index(rawCsrfTs.startIndex, offsetBy: 50)..<rawCsrfTs.characters.index(rawCsrfTs.endIndex, offsetBy: -6)
        let csrfTs = rawCsrfTs[rangeCsrfTs]
        DebugLog(csrfTs as AnyObject)

        DebugLog(">>> Отправка формы авторизации" as AnyObject);

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

            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            self.DebugLog(dataString!)

            self.DebugLog(">> Проверка доступа в интернет" as AnyObject);
            if (self.MosMetro.checkInternet()) {
                self.DebugLog("<< Соединение успешно установлено :3" as AnyObject);
            } else {
                self.DebugLog("<< Ошибка: доступ в интернет отсутствует" as AnyObject);
            }
        }) 

        task.resume()

        return true;
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        WifiName.text = MosMetro.getSSID()
        
        if (MosMetro.inMetro()) {
            DebugLog("> Проверка интернета..." as AnyObject)
            if (MosMetro.checkInternet()) {
                InternetState.text = "Есть"
                DebugLog("> Есть" as AnyObject)
            } else {
                InternetState.text = "Нет"
                DebugLog("> Нет" as AnyObject)
                DebugLog("> Произвожу подключение" as AnyObject)
                connectInternet()
            }
        } else {
            DebugLog("Вы не в метро, или проверьте настройки wi-fi" as AnyObject)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setNotification(_ body: String, action: String, time: TimeInterval) {
        let notificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)

        guard let settings = UIApplication.shared.currentUserNotificationSettings else { return }

        if settings.types == UIUserNotificationType() {
            let ac = UIAlertController(title: "Нет доступа", message: "Ты не дал мне доступ к уведомлениям, поэтому я не смогу тебе сообщить если, что-то сломалось", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(ac, animated: true, completion: nil)
            return
        }

        let notification = UILocalNotification()
        notification.fireDate = Date(timeIntervalSinceNow: time)
        notification.alertBody = body
        notification.alertAction = action
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.userInfo = ["CustomField1": "w00t"]
        UIApplication.shared.scheduleLocalNotification(notification)
    }

    func viewAlert(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))

        self.present(alertController, animated: true, completion: nil)
    }

}
