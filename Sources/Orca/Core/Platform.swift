import Foundation

enum Platform: Sendable {
    case iOS
    case macOS
    case tvOS
    case watchOS
    case visionOS

    static var current: Platform {
        #if os(iOS)
        return .iOS
        #elseif os(macOS)
        return .macOS
        #elseif os(tvOS)
        return .tvOS
        #elseif os(watchOS)
        return .watchOS
        #elseif os(visionOS)
        return .visionOS
        #endif
    }

    var storeName: String {
        "appstore"
    }
}
