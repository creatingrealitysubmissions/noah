//
//  AppDelegate.swift
//  Noah
//
//  Created by Edward Arenberg on 3/12/18.
//  Copyright © 2018 Edward Arenberg. All rights reserved.
//

import UIKit
import ArcGIS

var scene: AGSScene!

extension UIApplication {
    
    var screenShot: UIImage?  {
        
        if let layer = keyWindow?.layer {
            let scale = UIScreen.main.scale
            
            UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
            if let context = UIGraphicsGetCurrentContext() {
                layer.render(in: context)
                let screenshot = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return screenshot
            }
        }
        return nil
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    // Client ID : vQ0nwhUqFsto4M1V
    // Client Secret: b79c92aa5a9a4a6b832c1c04ef9d09a9
    
    // Temp Token : n299fB9BrHdNe8KXEFiCSFVMQPidHwEzNsPeVJ8OLeBezyFHlDtpM1Kgn2HrejasA5bj_aA88QWDzvAE6acs8wVH90fJjrIrHz4tp84dZleEwUQyRDJRffy0y6Ngsr86484ilcr6HtdG4JY6C53IWA

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        try? AGSArcGISRuntimeEnvironment.setLicenseKey("runtimelite,1000,rud3487322193,none,9TJC7XLS1MPH4P7EJ114")
        AGSArcGISRuntimeEnvironment.init()
        
        //Create an instance of a scene
        scene = AGSScene()
        //Define the basemap layer with ESRI imagery basemap
        scene.basemap = AGSBasemap.imagery()
        //Create a scene layer from a scene service and add it to a scene
        let philly = "http://scenesampleserverdev.arcgis.com/arcgis/rest/services/Hosted/Buildings_Philadelphia/SceneServer/layers/0"
        let brest = "https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/Buildings_Brest/SceneServer/layers/0"
        
        let sceneLayer = AGSArcGISSceneLayer(url: URL(string: philly)!)
        scene.operationalLayers.add(sceneLayer)
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
    }


}

