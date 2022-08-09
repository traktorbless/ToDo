import UIKit

extension UIColor {
    static let background = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        default:
            return UIColor(red: 0.97, green: 0.97, blue: 0.95, alpha: 1.0)
        }
    }

    static let backgroundGray = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
        default:
            return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
    }

    static let blueApp = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1.0)
        default:
            return UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        }
    }

    static let greenApp = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(red: 0.2, green: 0.84, blue: 0.29, alpha: 1.0)
        default:
            return UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0)
        }
    }

    static let redApp = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0)
        default:
            return UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
        }
    }
}
