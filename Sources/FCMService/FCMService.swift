import FirebaseMessaging
import UIKit
import Firebase
import UserNotifications
@objc public protocol FCMServiceDelegate {
    func onOpen()
    @objc optional func setNotificationCategory() -> UNNotificationCategory
    @objc optional func setNotificationSound() -> String
}

public class FCMService: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate  {
    public static let shared = FCMService()
    public var handlerDelegate : FCMServiceDelegate?
    
    private var category : UNNotificationCategory?
    private var soundName : String?
    
    
    
    private override init() {
        super.init()
    }
    

    public func setDeviceToken(devivceToken: Data){
        Messaging.messaging().apnsToken = devivceToken
    }
    
    public func getCategoryIdentifier() -> String{
        return category?.identifier ?? ""
    }
    
    public func setCategory(_ categories: UNNotificationCategory){
        category = categories
    }
    
    public func requestPushNotification(_ application: UIApplication) -> Bool {
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            let options = FirebaseOptions(contentsOfFile: filePath)
            FirebaseApp.configure(options: options!)
        }
        else{
            print("Please add Google Info to your project")
            return false
        }
        if #available(iOS 11.0, *) {
                    UNUserNotificationCenter.current().delegate = self
                    Messaging.messaging().delegate = self
                    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                    UNUserNotificationCenter.current().requestAuthorization(
                        options: authOptions,
                        completionHandler: {_, _ in })
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
                } else {
                    let settings: UIUserNotificationSettings =
                        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                    application.registerUserNotificationSettings(settings)
                    application.registerForRemoteNotifications()
                }
        
        if let category = handlerDelegate?.setNotificationCategory?() {
            UserDefaults(suiteName: "group.MyFCMApp")?.set(category.identifier, forKey: "CategoryName")
        }
        if let soundName = handlerDelegate?.setNotificationSound?() {
            UserDefaults(suiteName: "group.MyFCMApp")?.set(soundName, forKey: "SoundName")
        }

        return true

    }
    public func registerCategory() {
        UNUserNotificationCenter.current().delegate = self
        guard let categoryNamePushBack = handlerDelegate?.setNotificationCategory?() else {return}
        category = categoryNamePushBack
        UNUserNotificationCenter.current().setNotificationCategories([category!])
      }
    
}

extension FCMService {
    @available(iOS 13.0.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
            print(userInfo)
            return [[.alert,.sound]]
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        defer { completionHandler() }
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        let identity = response.notification.request.content.categoryIdentifier
        print(identity)
        guard identity == category?.identifier else { return }
        handlerDelegate?.onOpen()
    }
    
    
}

extension FCMService {
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FIREBASE TOKEN: \(String(describing: fcmToken))")
        
        let dataDict : [String:String] = ["token" : fcmToken ?? ""]
        
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}
