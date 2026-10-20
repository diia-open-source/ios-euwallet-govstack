import Foundation
import WalletDomainModels

public enum AppDateStyle {
    case dayMonthYearText
    case dayMonthYearNumeric
    case dayMonthYearHourMinute
}

public enum AppDateSourceFormat: CaseIterable {
    case yyyyMMdd
    case ddMMyyyy
    case dayMonthYearText
    case dayMonthYearHourMinute
    case iso8601
}

public enum AppDateFormatter {
    public static func string(from date: Date, style: AppDateStyle) -> String {
        switch style {
        case .dayMonthYearText:
            return dayMonthYearTextFormatter.string(from: date)
        case .dayMonthYearNumeric:
            return ddMMyyyyFormatter.string(from: date)
        case .dayMonthYearHourMinute:
            return dayMonthYearHourMinuteFormatter.string(from: date)
        }
    }

    public static func date(from string: String, source: AppDateSourceFormat) -> Date? {
        let normalizedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedString.isEmpty else { return nil }

        switch source {
        case .yyyyMMdd:
            return yyyyMMddFormatter.date(from: normalizedString)
        case .ddMMyyyy:
            return ddMMyyyyFormatter.date(from: normalizedString)
        case .dayMonthYearText:
            return dayMonthYearTextFormatter.date(from: normalizedString)
        case .dayMonthYearHourMinute:
            return dayMonthYearHourMinuteFormatter.date(from: normalizedString)
        case .iso8601:
            return iso8601FractionalFormatter.date(from: normalizedString)
                ?? iso8601Formatter.date(from: normalizedString)
        }
    }

    private static func reformat(
        _ value: String,
        from source: AppDateSourceFormat,
        to style: AppDateStyle
    ) -> String? {
        guard let date = date(from: value, source: source) else { return nil }
        return AppDateFormatter.string(from: date, style: style)
    }

    public static func bestEffortReformat(
        _ value: String,
        preferredSources: [AppDateSourceFormat] = AppDateSourceFormat.allCases,
        to style: AppDateStyle
    ) -> String {
        for source in preferredSources {
            if let formattedString = reformat(value, from: source, to: style) {
                return formattedString
            }
        }
        return value
    }

    private static let plainDateCalendar = Calendar(identifier: .gregorian)
    private static let plainDateLocale = Locale(identifier: "en_US_POSIX")
    private static let plainDateTimeZone = TimeZone(secondsFromGMT: 0) ?? .current

    private static let yyyyMMddFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = plainDateCalendar
        formatter.locale = plainDateLocale
        formatter.timeZone = plainDateTimeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let ddMMyyyyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = plainDateCalendar
        formatter.locale = plainDateLocale
        formatter.timeZone = plainDateTimeZone
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    private static let dayMonthYearTextFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = plainDateCalendar
        formatter.locale = plainDateLocale
        formatter.timeZone = plainDateTimeZone
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()

    private static let dayMonthYearHourMinuteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = plainDateCalendar
        formatter.locale = plainDateLocale
        formatter.timeZone = .current
        formatter.dateFormat = "dd MMM yyyy HH:mm"
        return formatter
    }()

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let iso8601FractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
