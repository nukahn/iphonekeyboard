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
    case cursorLeft   = 0x05
    case cursorRight  = 0x06
    case cursorUp     = 0x07
    case cursorDown   = 0x08
    case selectAll    = 0x09
    case copy         = 0x0A
    case paste        = 0x0B
}
