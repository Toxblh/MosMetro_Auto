//
//  AppDelegate.swift
//  MosMetro_Auto
//
//  Created by Anton Palgunov on 25.04.16.
//  Copyright © 2016 toxblh. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(
            expirationHandler: {
                Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(AppDelegate.update), userInfo: nil, repeats: true)
        })
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(AppDelegate.update), userInfo: nil, repeats: true)
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Fetch");
        var timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(AppDelegate.update), userInfo: nil, repeats: true)
    }
    
    func update() {
        let m = MosMetroAPI();
        if (m.inMetro()){
            print("В метро");
            if (!m.checkInternet()) {
                if (m.connect()) {
                    setNotification("Успешное подключение к wi-fi", action: "Реально в метро!)", time: 0);
                } else {
                    setNotification("Не смог подключиться к wi-fi", action: "Реально в метро!)", time: 0);
                }
            }
        } else {
            print("Не в метро");
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func setNotification(_ body: String, action: String, time: TimeInterval) {
        let notification = UILocalNotification()
        notification.fireDate = Date(timeIntervalSinceNow: time)
        notification.alertBody = body
        notification.alertAction = action
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.userInfo = ["CustomField1": "w00t"]
        UIApplication.shared.scheduleLocalNotification(notification)
    }

}

