
import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var locationManager: CLLocationManager?
    var lastProximity: CLProximity?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        let uuidString = NSBundle.mainBundle().objectForInfoDictionaryKey("beaconUuidString") as String
        let beaconIdentifier = NSBundle.mainBundle().objectForInfoDictionaryKey("beaconIdentifier") as String
        let beaconUUID:NSUUID = NSUUID(UUIDString: uuidString)!
        let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID: beaconUUID,
            identifier: beaconIdentifier)
        
        locationManager = CLLocationManager()
        
        if(locationManager!.respondsToSelector("requestAlwaysAuthorization")) {
            locationManager!.requestAlwaysAuthorization()
        }
        
        locationManager!.delegate = self
        locationManager!.pausesLocationUpdatesAutomatically = false
        
        locationManager!.startMonitoringForRegion(beaconRegion)
        locationManager!.startRangingBeaconsInRegion(beaconRegion)
        locationManager!.startUpdatingLocation()
        
        if(application.respondsToSelector("registerUserNotificationSettings:")) {
            application.registerUserNotificationSettings(
                UIUserNotificationSettings(
                    forTypes: UIUserNotificationType.Alert | UIUserNotificationType.Sound,
                    categories: nil
                )
            )
        }
        
        println("Application started")
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
        NSNotificationCenter.defaultCenter().postNotificationName("kSaveDataPoolNotification", object: nil);
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    func sendLocalNotificationWithMessage(message: String!) {
        let notification:UILocalNotification = UILocalNotification()
        notification.alertBody = message
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func locationManager(manager: CLLocationManager!,
        didRangeBeacons beacons: [AnyObject]!,
        inRegion region: CLBeaconRegion!) {
            
            var rootViewController = self.window!.rootViewController as UINavigationController


            let tasksViewController:TasksViewController = rootViewController.viewControllers[0] as TasksViewController
            
            
            var tasks = tasksViewController.tasks
            
            for beacon in beacons {
                for task in tasks {
                    if( task.beacon.minor == beacon.minor && task.beacon.major == beacon.major) {
                        if (beacon.proximity == CLProximity.Immediate || beacon.proximity == CLProximity.Near) {
                            task.isSelectable = true
                        } else {
                            task.isSelectable = false
                        }
                        
                    } else {
                        task.isSelectable = false
                    }
                }
            }
            
            tasksViewController.tableView!.reloadData()
            
            //println("didRangeBeacons");
            var message:String = ""
            
            
            if(beacons.count > 0) {
                let nearestBeacon:CLBeacon = beacons[0] as CLBeacon
                
                if(nearestBeacon.proximity == lastProximity ||
                    nearestBeacon.proximity == CLProximity.Unknown) {
                        return;
                }
                lastProximity = nearestBeacon.proximity;
                
                switch nearestBeacon.proximity {
                case CLProximity.Far:
                    message = "You are far away from the beacon"
                case CLProximity.Near:
                    message = "You are near the beacon"
                case CLProximity.Immediate:
                    message = "You are in the immediate proximity of the beacon"
                case CLProximity.Unknown:
                    return
                }
            } else {
                
                if(lastProximity == CLProximity.Unknown) {
                    return;
                }
                
                message = "No beacons are nearby"
                lastProximity = CLProximity.Unknown
            }
            
            NSLog("%@", message)
            //sendLocalNotificationWithMessage(message)
    }
    
    func locationManager(manager: CLLocationManager!,
        didEnterRegion region: CLRegion!) {
            manager.startRangingBeaconsInRegion(region as CLBeaconRegion)
            manager.startUpdatingLocation()
            
            NSLog("You entered the region")
            //sendLocalNotificationWithMessage("You entered the region")
    }
    
    func locationManager(manager: CLLocationManager!,
        didExitRegion region: CLRegion!) {
            manager.stopRangingBeaconsInRegion(region as CLBeaconRegion)
            manager.stopUpdatingLocation()
            
            NSLog("You exited the region")
            //sendLocalNotificationWithMessage("You exited the region")
    }
}

