import SwiftUI

/// Live validation for the sign-up and login forms.
enum FieldState: Equatable {
    case empty
    case valid
    case invalid(String)

    var message: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }

    var isValid: Bool { self == .valid }
}

enum FormValidation {
    static func name(_ value: String) -> FieldState {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .empty }
        return trimmed.count >= 2 ? .valid : .invalid(String(localized: "Please enter your name."))
    }

    static func age(_ value: String) -> FieldState {
        if value.isEmpty { return .empty }
        guard let age = Int(value) else { return .invalid(String(localized: "Enter your age as a number.")) }
        if age < 13 { return .invalid(String(localized: "You need to be at least 13 to use Ritm.")) }
        if age > 120 { return .invalid(String(localized: "Please enter a valid age.")) }
        return .valid
    }

    static func email(_ value: String) -> FieldState {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .empty }
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
            ? .valid
            : .invalid(String(localized: "That email doesn't look right."))
    }

    static func phone(_ value: String) -> FieldState {
        if value.isEmpty { return .empty }
        let digits = value.filter(\.isNumber)
        let allowed = CharacterSet(charactersIn: "+0123456789 -()")
        guard value.unicodeScalars.allSatisfy(allowed.contains) else {
            return .invalid(String(localized: "Use digits only, e.g. +966 5X XXX XXXX."))
        }
        return (8...15).contains(digits.count) ? .valid : .invalid(String(localized: "Enter a full phone number with country code."))
    }

    static func password(_ value: String) -> FieldState {
        if value.isEmpty { return .empty }
        return PasswordStrength(value).meetsMinimum
            ? .valid
            : .invalid(String(localized: "Use at least 8 characters with a letter and a number."))
    }

    static func confirm(_ value: String, matches password: String) -> FieldState {
        if value.isEmpty { return .empty }
        return value == password ? .valid : .invalid(String(localized: "Passwords don't match."))
    }
}

struct PasswordStrength {
    let hasLength: Bool
    let hasLetter: Bool
    let hasNumber: Bool
    let hasSymbol: Bool
    let isLong: Bool

    init(_ password: String) {
        hasLength = password.count >= 8
        hasLetter = password.contains(where: \.isLetter)
        hasNumber = password.contains(where: \.isNumber)
        hasSymbol = password.contains { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }
        isLong = password.count >= 12
    }

    var meetsMinimum: Bool { hasLength && hasLetter && hasNumber }

    /// 0 … 4
    var score: Int {
        guard !(!hasLength && !hasLetter && !hasNumber) else { return 0 }
        var score = 0
        if hasLength { score += 1 }
        if hasLetter && hasNumber { score += 1 }
        if hasSymbol { score += 1 }
        if isLong { score += 1 }
        return max(score, 1)
    }

    var label: String {
        switch score {
        case 0, 1: String(localized: "Weak")
        case 2: String(localized: "Okay")
        case 3: String(localized: "Strong")
        default: String(localized: "Very strong")
        }
    }

    var color: Color {
        switch score {
        case 0, 1: .red
        case 2: .orange
        case 3: .green
        default: .mint
        }
    }
}
