import Foundation

enum CardKind: String, CaseIterable, Identifiable {
    case credit
    case debit
    case prepaid
    case loyalty
    case membership
    case gift
    case other

    var id: Self { self }

    var title: String {
        switch self {
        case .credit: "Credit"
        case .debit: "Debit"
        case .prepaid: "Prepaid"
        case .loyalty: "Loyalty"
        case .membership: "Membership"
        case .gift: "Gift card"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .credit, .debit, .prepaid: "creditcard"
        case .loyalty: "star"
        case .membership: "person.text.rectangle"
        case .gift: "gift"
        case .other: "rectangle.on.rectangle"
        }
    }

    /// Only payment cards get the EMV chip and contactless mark.
    var isPaymentCard: Bool {
        switch self {
        case .credit, .debit, .prepaid: true
        default: false
        }
    }
}

enum CardNetwork: String, CaseIterable, Identifiable {
    case visa
    case mastercard
    case amex
    case maestro
    case discover
    case rupay
    case none

    var id: Self { self }

    var title: String {
        switch self {
        case .visa: "Visa"
        case .mastercard: "Mastercard"
        case .amex: "American Express"
        case .maestro: "Maestro"
        case .discover: "Discover"
        case .rupay: "RuPay"
        case .none: "None"
        }
    }
}
