import Foundation

enum SharedConstants {
    static let appGroupID = "group.com.remotekeyboard"
    static let serviceType = "remotekb"
    static let darwinNotificationName = "com.remotekeyboard.newInput"
    static let pendingInputKey = "pendingInput"
    static let pendingInputTimestampKey = "pendingInputTimestamp"
}

// Message prefix bytes
enum MessageType: UInt8 {
    case insertText   = 0x01
    case deleteOne    = 0x02
    case deleteN      = 0x03
    case returnKey    = 0x04
}
