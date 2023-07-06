//
//  NotificationService.swift
//  MyNotificationService
//
//  Created by Huynh Minh Hieu on 22/06/2023.
//

import UserNotifications
import  FCMService

@objc public protocol NotificationServiceDelegate {
    @objc func setCategoryIdentifier() -> String
}

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            bestAttemptContent.title = "\(bestAttemptContent.body) add some modify here"
            if var aps = bestAttemptContent.userInfo["aps"] as? [String:AnyHashable] {
                aps["content-available"] = 1
            }
            
            if let categoryIdentifier = UserDefaults(suiteName:"group.MyFCMApp")!.object(forKey: "CategoryName") as? String {
                bestAttemptContent.categoryIdentifier = categoryIdentifier
            }
          
            
            if let soundName = UserDefaults(suiteName: "group.MyFCMApp")!.object(forKey: "SoundName") as? String {
                bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
            }
            
            
            
            //handle image
            var urlString:String? = nil
            if let urlImageString = request.content.userInfo["fcm_options"] as? [String:AnyHashable] {
                urlString = urlImageString["image"] as? String
                }
                        
                        if urlString != nil, let fileUrl = URL(string: urlString!) {
                            print("fileUrl: \(fileUrl)")
                            
                            guard let imageData = NSData(contentsOf: fileUrl) else {
                                contentHandler(bestAttemptContent)
                                return
                            }
                            guard let attachment = UNNotificationAttachment.saveImageToDisk(fileIdentifier: "image.jpg", data: imageData, options: nil) else {
                                print("error in UNNotificationAttachment.saveImageToDisk()")
                                contentHandler(bestAttemptContent)
                                return
                            }
                            
                            bestAttemptContent.attachments = [ attachment ]
                        }
                        
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}

@available(iOSApplicationExtension 10.0, *)
extension UNNotificationAttachment {
    
    static func saveImageToDisk(fileIdentifier: String, data: NSData, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let folderName = ProcessInfo.processInfo.globallyUniqueString
        let folderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(folderName, isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: folderURL!, withIntermediateDirectories: true, attributes: nil)
            let fileURL = folderURL?.appendingPathComponent(fileIdentifier)
            try data.write(to: fileURL!, options: [])
            let attachment = try UNNotificationAttachment(identifier: fileIdentifier, url: fileURL!, options: options)
            return attachment
        } catch let error {
            print("error \(error)")
        }
        
        return nil
    }
}
