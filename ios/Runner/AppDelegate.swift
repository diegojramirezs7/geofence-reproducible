import UIKit
import Flutter
import CoreLocation
import Alamofire
import SystemConfiguration

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  
  var locationManager: CLLocationManager?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let geofencingChannel = FlutterMethodChannel(name: "com.tradespecifix.geofencing",
                                      binaryMessenger: controller.binaryMessenger)
    
    geofencingChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        
        if (call.method == "initializeHost") {
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager = CLLocationManager()
                self.locationManager?.delegate = self
                self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
                self.locationManager?.allowsBackgroundLocationUpdates = true
                //self.saveDataToFile(myString: "[]")

                if let args = call.arguments as? Dictionary<String, Any>,
                  let name = args["user_name"] as? String {
                  let defaults = UserDefaults.standard
                  defaults.set(name, forKey: "tradespecifix_user_name")
                }
                
                result("true")
            }
            result("false")
        } else if(call.method == "registerGeofence"){
            if let args = call.arguments as? Dictionary<String, Any>,
              let latitude = args["latitude"] as? Double, 
              let longitude = args["longitude"] as? Double,
              let radius = args["radius"] as? Double, 
              let name = args["name"] as? String {
                
                let value = startGeofencing(latitude: latitude, longitude: longitude, identifier: name, radius: radius);
                let res = String(value)
                result(res)
            } else {
                // do something
                result("false");
            }

        result("false");
      } else if (call.method == "testHTTP"){
        let value = testHttp()
        result(value)
      } else if (call.method == "removeAllGeofences") {
        let value = removeAllGeofences()
        result(value)
      }
      else if (call.method == "getAllGeofences") {
        let value = getAllGeofences()
        result(value)
      }
      else if (call.method == "removeGeofenceById") {
        if let args = call.arguments as? Dictionary<String, Any>,
           let identifier = args["identifier"] as? String {
            
            let value = removeGeofenceById(identifier: identifier)
            result(value)
        }
        result("Identifier argument is needed")
      } else if (call.method == "randomTest") {
        print("made it here")
        let fileString = self.readDataFromFile()
        print(fileString)
        result(fileString)
       }else if (call.method == "test") {
          let regions = self.locationManager?.monitoredRegions
          var region: CLRegion?

          for reg in regions! {
              if reg.identifier == "1" {
                  region = reg
              }
          }

         self.locationManager(self.locationManager!, didEnterRegion: region!)
         result("true")
        
       } else if (call.method == "sendFileData") {
        let val = sendFileData() ?? ""
        result(val)
       }
    })
    
    func sendFileData() -> String? {
        let fileDataString = readDataFromFile()
        
        if fileDataString != "[]" {
            let jsonData = fileDataString.data(using: .utf8)!
            let eventLogs: [GEvent] = try! JSONDecoder().decode([GEvent].self, from: jsonData)
            let endpoint = "https://safe-falls-49683.herokuapp.com/events/"
            
            for el in eventLogs {
                //print(el.time)
                AF.request(endpoint, method: .post, parameters: el, encoder:  JSONParameterEncoder.default).responseJSON {response in
                    guard let json = response.value else { return }
                    print(json)
                }
            }
        }
        saveDataToFile(myString: "[]")
        return "file data sent"
    }
    

    func testHttp() -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: Date())
        let endpoint: String = "https://safe-falls-49683.herokuapp.com/events/"

        let defaults = UserDefaults.standard
        let my_name = defaults.string(forKey: "tradespecifix_user_name") ?? ""

        struct GEvent: Encodable {
            let event: String
            let geofence: String
            let time: String
            let phone_os: String
            let user_name: String
        }

        let eventLog = GEvent(event: "exit", geofence: "1", time: dateString, phone_os: "iOS", user_name: my_name)
        
        let result = "success"
        
        AF.request(endpoint, method: .post, parameters: eventLog, encoder:  JSONParameterEncoder.default).responseJSON {response in
            guard let json = response.value else { return }
            print(json)
        }
        
        return result
    }
    
    func startGeofencing(latitude: Double, longitude: Double,
                         identifier: String, radius: Double) -> Bool {
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
               
          let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
          let circularRegion = CLCircularRegion(center: coordinates, radius: radius, identifier: identifier)
          circularRegion.notifyOnExit = true
          circularRegion.notifyOnEntry = true
                
          self.locationManager?.startMonitoring(for: circularRegion)
          // print("started")
          return true               
        }
        return false
    }

    func getAllGeofences() -> String {
      let regions = self.locationManager?.monitoredRegions
      var result = ""

      for region in regions! {
        result += "\(region.identifier) "
      }

      return result
    }

    func removeGeofenceById(identifier: String) -> String {
      
      let regions = self.locationManager?.monitoredRegions

      for region in regions! {
        if region.identifier == identifier {
            self.locationManager?.stopMonitoring(for: region)
            return "true"
        }
      }

      return "Region not found"
    }

    func removeAllGeofences() -> String {
        let regions = self.locationManager?.monitoredRegions

        for region in regions! {
            self.locationManager?.stopMonitoring(for: region)
        }
        
        return "got here baby"
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

class Reachability {
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }

        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }

        /* Only Working for WIFI
        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired

        return isReachable && !needsConnection
        */

        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)

        return ret
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    struct GEvent: Encodable, Decodable {
      let event: String
      let geofence: String
      let time: String
      let phone_os: String
      let user_name: String
    }
    
    func saveDataToFile(myString: String) {
        let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let fileUrl = URL(fileURLWithPath: "tradespecifix_geofence_logs", relativeTo: directoryURL).appendingPathExtension("txt")
        
        guard let data = myString.data(using: .utf8) else {
            print("Unable to convert string to data")
            return
        }
        
        do {
         try data.write(to: fileUrl)
         print("File saved: \(fileUrl.absoluteURL)")
        } catch {
         // Catch any errors
         print(error.localizedDescription)
        }
    }
    
    func readDataFromFile() -> String {
        let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let fileUrl = URL(fileURLWithPath: "tradespecifix_geofence_logs", relativeTo: directoryURL).appendingPathExtension("txt")
        
        do {
         // Get the saved data
         let savedData = try Data(contentsOf: fileUrl)
         // Convert the data back into a string
         if let savedString = String(data: savedData, encoding: .utf8) {
            print(savedString)
            return savedString
         }
         print("failed to get savedString")
        } catch {
         // Catch any errors
         print("Unable to read the file")
        }

        return "[]"
    }
    
    func addEventToFile(event_log: GEvent) {
        let fileDataString = readDataFromFile()
        let jsonData = fileDataString.data(using: .utf8)!
        var eventLogs: [GEvent] = try! JSONDecoder().decode([GEvent].self, from: jsonData)
        eventLogs.append(event_log)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(eventLogs)
            let finalString = String(data: data, encoding: .utf8)!
            saveDataToFile(myString: finalString)
            print(finalString)
        } catch {
            print("something went wrong")
        }
    }
    
    
  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    let identifier = region.identifier
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateString = formatter.string(from: Date())

    let endpoint: String = "https://safe-falls-49683.herokuapp.com/events/"

    let defaults = UserDefaults.standard
    let my_name = defaults.string(forKey: "tradespecifix_user_name") ?? ""
    let eventLog = GEvent(event: "enter", geofence: identifier, time: dateString, phone_os: "iOS", user_name: my_name)
    
    addEventToFile(event_log: eventLog)
    
    if Reachability.isConnectedToNetwork() {
        AF.request(endpoint, method: .post, parameters: eventLog, encoder: JSONParameterEncoder.default).responseJSON {response in
          guard let json = response.value else { return }
          print(json)
        }
    }
  }
    
    // catch notification when user exits the region
  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    let identifier = region.identifier
            
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateString = formatter.string(from: Date())

    let endpoint: String = "https://safe-falls-49683.herokuapp.com/events/"

    let defaults = UserDefaults.standard
    let my_name = defaults.string(forKey: "tradespecifix_user_name") ?? ""
    let eventLog = GEvent(event: "exit", geofence: identifier, time: dateString, phone_os: "iOS", user_name: my_name)
    addEventToFile(event_log: eventLog)
    
    if Reachability.isConnectedToNetwork() {
        AF.request(endpoint, method: .post, parameters: eventLog, encoder: JSONParameterEncoder.default).responseJSON {response in
          guard let json = response.value else { return }
          print(json)
        }
    } 
  }

  func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
    print(region.identifier)
    print(state)
  }
}
