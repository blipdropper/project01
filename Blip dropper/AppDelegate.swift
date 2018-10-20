//
//  AppDelegate.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 8/12/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.
//
//  ToDo: why does post redirect to feed, compress images, add location to blip post, get the image URL (poke around Ubuntu?)
//  ISSUE: insecure text data transfer, not using blipdropper.com
//  ISSUE: need to request access to camera roll and enable camera
//  ISSUE: need to convert to VC with tableview vs. custom TableViewVC because floating button will break


import UIKit
import CoreData
import Parse


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        /*
        //----------------------
        // Log users local date/time
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = "Current date is: \(dateFormatter.string(from: Date() as Date))"
        print(String(dateString))
        //Time
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .medium
        let timeString = "Current time is: \(timeFormatter.string(from: Date() as Date))"
        print(String(timeString))
        */
        // Initialize Parse-server
        let configuration = ParseClientConfiguration {
            $0.applicationId = "c4f3ec23021d93ae802698b4003fce5cb5120d07"
            $0.clientKey = "ac27fd1b32274bda6f81051c4ff198f23050f8bd"
            //            $0.applicationId = "b291cf81e6917850bf5c0922ae686e171d43fa5e"
            //            $0.clientKey = "4d519cc6a5672f08d6f703c3e6c7900cf79de035"
            $0.server = "http://dev.blipdropper.com/parse"
            // test somehow that the connection worked
        }
        Parse.initialize(with: configuration)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Blip_dropper")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

