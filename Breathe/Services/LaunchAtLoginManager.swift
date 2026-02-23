import ServiceManagement

final class LaunchAtLoginManager {
    private let service = SMAppService.mainApp

    var isEnabled: Bool {
        service.status == .enabled
    }

    func syncState(with settings: UserSettings) {
        if settings.launchAtLogin && !isEnabled {
            enable()
        } else if !settings.launchAtLogin && isEnabled {
            disable()
        }
    }

    func enable() {
        do {
            try service.register()
        } catch {
            print("Failed to enable launch at login: \(error)")
        }
    }

    func disable() {
        do {
            try service.unregister()
        } catch {
            print("Failed to disable launch at login: \(error)")
        }
    }
}
