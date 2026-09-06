import Foundation
import UserNotifications
import AudioToolbox
import AVFoundation

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permissions granted")
            }
        }
    }
    
    func playAlertSound() {
        // System sound 1007 is SMS alert sound on iOS
        AudioServicesPlaySystemSound(1007)
        // Vibrate
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    func showLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // immediate
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
        
        playAlertSound()
    }
}