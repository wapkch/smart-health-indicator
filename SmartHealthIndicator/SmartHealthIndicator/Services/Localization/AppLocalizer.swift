import Foundation

enum AppLocalizer {
    static func string(_ key: String) -> String {
        Bundle(for: BundleToken.self).localizedString(forKey: key, value: key, table: nil)
    }
}

private final class BundleToken {}
