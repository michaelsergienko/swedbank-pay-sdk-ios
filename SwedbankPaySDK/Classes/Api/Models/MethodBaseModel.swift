//
// Copyright 2024 Swedbank AB
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

enum MethodBaseModel: Codable, Equatable, Hashable {
    case swish(prefills: [SwedbankPaySDK.SwishMethodPrefillModel]?, operations: [OperationOutputModel]?)
    case creditCard(prefills: [SwedbankPaySDK.CreditCardMethodPrefillModel]?, operations: [OperationOutputModel]?, cardBrands: [String]?)
    case applePay(operations: [OperationOutputModel]?, cardBrands: [String]?, merchantCapabilities: [String]?)
    case webBased(paymentMethod: String)

    private enum CodingKeys: String, CodingKey {
        case paymentMethod, prefills, operations, cardBrands, merchantCapabilities
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let paymentMethod = try container.decode(String.self, forKey: .paymentMethod)
        switch paymentMethod {
        case "Swish":
            self = .swish(
                prefills: try? container.decode([SwedbankPaySDK.SwishMethodPrefillModel]?.self, forKey: CodingKeys.prefills),
                operations: try? container.decode([OperationOutputModel]?.self, forKey: CodingKeys.operations)
            )
        case "CreditCard":
            self = .creditCard(
                prefills: try? container.decode([SwedbankPaySDK.CreditCardMethodPrefillModel].self, forKey: CodingKeys.prefills),
                operations: try? container.decode([OperationOutputModel]?.self, forKey: CodingKeys.operations),
                cardBrands: try? container.decode([String]?.self, forKey: CodingKeys.cardBrands)
            )
        case "ApplePay":
            self = .applePay(
                operations: try? container.decode([OperationOutputModel]?.self, forKey: CodingKeys.operations),
                cardBrands: try? container.decode([String]?.self, forKey: CodingKeys.cardBrands),
                merchantCapabilities: try? container.decode([String]?.self, forKey: CodingKeys.merchantCapabilities)
            )
        default:
            self = .webBased(paymentMethod: paymentMethod)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .swish(let prefills, let operations):
            try container.encode(prefills)
            try container.encode(operations)
        case .creditCard(let prefills, let operations, let cardBrands):
            try container.encode(prefills)
            try container.encode(operations)
            try container.encode(cardBrands)
        case .applePay(let operations, let cardBrands, let merchantCapabilities):
            try container.encode(operations)
            try container.encode(cardBrands)
            try container.encode(merchantCapabilities)
        case .webBased(let paymentMethod):
            try container.encode(paymentMethod)
        }
    }

    var name: String {
        switch self {
        case .swish:
            return "Swish"
        case .creditCard:
            return "CreditCard"
        case .applePay:
            return "ApplePay"
        case .webBased(let paymentMethod):
            return paymentMethod
        }
    }

    var operations: [OperationOutputModel]? {
        switch self {
        case .swish(_, let opertations):
            return opertations
        case .creditCard(_, let opertations, _):
            return opertations
        case .applePay(let operations, _, _):
            return operations
        case .webBased:
            return nil
        }
    }
}

extension Sequence where Iterator.Element == MethodBaseModel
{
    func firstMethod(withName name: String) -> MethodBaseModel? {
        return first(where: { $0.name == name })
    }
}

extension SwedbankPaySDK {
    /// Avilable instrument for Native Payment.
    public enum AvailableInstrument: Codable, Equatable, Hashable {

        /// Swish native payment with a list of prefills
        case swish(prefills: [SwishMethodPrefillModel]?)

        case creditCard(prefills: [CreditCardMethodPrefillModel]?)

        case applePay(canMakePayments: Bool, canMakePaymentsUsingNetworksAndCapabilities: Bool)

        case webBased(paymentMethod: String)

        public var paymentMethod: String {
            switch self {
            case .swish:
                return "Swish"
            case .creditCard:
                return "CreditCard"
            case .applePay:
                return "ApplePay"
            case .webBased(let paymentMethod):
                return paymentMethod
            }
        }
    }

    /// Prefill information for Swish payment.
    public struct SwishMethodPrefillModel: Codable, Hashable {
        public let rank: Int32
        public let msisdn: String
    }

    /// Prefill information for Credit Card payment.
    public struct CreditCardMethodPrefillModel: Codable, Hashable {
        public let rank: Int32
        public let paymentToken: String
        public let cardBrand: String
        public let maskedPan: String
        public let expiryDate: Date

        public var expiryMonth: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM"
            formatter.timeZone = TimeZone(identifier: "UTC")

            return formatter.string(from: expiryDate)
        }

        public var expiryYear: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "YY"
            formatter.timeZone = TimeZone(identifier: "UTC")

            return formatter.string(from: expiryDate)
        }

        public var expiryString: String {
            return expiryMonth + "/" + expiryYear
        }
    }
}
