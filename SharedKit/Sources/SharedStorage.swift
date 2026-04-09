import Foundation

final class SharedStorage {
    static let shared = SharedStorage()

    private let defaults: UserDefaults?

    init(suiteName: String = SharedConstants.appGroupID) {
        defaults = UserDefaults(suiteName: suiteName)
    }

    func save(messageData: Data) {
        defaults?.set(messageData, forKey: SharedConstants.pendingInputKey)
        defaults?.set(Date().timeIntervalSince1970, forKey: SharedConstants.pendingInputTimestampKey)
        defaults?.synchronize()
    }

    func read() -> (data: Data, timestamp: Double)? {
        guard let data = defaults?.data(forKey: SharedConstants.pendingInputKey) else { return nil }
        let timestamp = defaults?.double(forKey: SharedConstants.pendingInputTimestampKey) ?? 0
        return (data, timestamp)
    }

    func clear() {
        defaults?.removeObject(forKey: SharedConstants.pendingInputKey)
        defaults?.synchronize()
    }
}
