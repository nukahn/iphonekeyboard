import Foundation

// File-level storage (required: C callbacks cannot capture Swift instance state)
private var _darwinCallbacks: [String: [() -> Void]] = [:]
private let _darwinLock = NSLock()

// C-compatible callback — invokes registered Swift closures by notification name
private let _darwinCCallback: CFNotificationCallback = { _, _, cfName, _, _ in
    guard let name = cfName?.rawValue as String? else { return }
    _darwinLock.lock()
    let cbs = _darwinCallbacks[name] ?? []
    _darwinLock.unlock()
    cbs.forEach { $0() }
}

/// Thread-safe wrapper for Darwin cross-process notifications.
/// Used to signal the keyboard extension when the host app receives new text.
final class DarwinNotificationCenter {
    static let shared = DarwinNotificationCenter()
    private init() {}

    func post(_ name: String) {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(name as CFString),
            nil, nil, true
        )
    }

    func observe(_ name: String, callback: @escaping () -> Void) {
        _darwinLock.lock()
        let isNew = _darwinCallbacks[name] == nil
        if isNew { _darwinCallbacks[name] = [] }
        _darwinCallbacks[name]?.append(callback)
        _darwinLock.unlock()

        if isNew {
            CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                nil,
                _darwinCCallback,
                name as CFString,
                nil,
                .deliverImmediately
            )
        }
    }

    func removeObservers(for name: String) {
        _darwinLock.lock()
        _darwinCallbacks[name] = nil
        _darwinLock.unlock()
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            CFNotificationName(name as CFString),
            nil
        )
    }
}
