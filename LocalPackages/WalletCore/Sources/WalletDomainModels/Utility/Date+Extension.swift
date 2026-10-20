import Foundation

public extension Date {
    func toLongDateString(locale: Locale = Locale(identifier: "en_US")) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        dateFormatter.locale = locale
        dateFormatter.timeZone = TimeZone.current

        return dateFormatter.string(from: self)
    }
}
