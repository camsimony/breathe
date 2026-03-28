import AppKit
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate {
    let userSettings = UserSettings()
    let overlayController = OverlayWindowController()
    let reminderScheduler = ReminderScheduler()
    let launchAtLoginManager = LaunchAtLoginManager()
    lazy var settingsPanelController = SettingsPanelController(settings: userSettings)

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        reminderScheduler.configure(with: userSettings)
        launchAtLoginManager.syncState(with: userSettings)
    }

    func showSettings() {
        settingsPanelController.show()
    }

    // MARK: - Notification Delegate

    /// Handle notification tap -- start a breathing session
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        overlayController.show(settings: userSettings)
        completionHandler()
    }

    /// Show notification even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Suppress during active breathing session
        if overlayController.isShowingSession {
            completionHandler([])
        } else {
            completionHandler([.banner, .sound])
        }
    }
}
