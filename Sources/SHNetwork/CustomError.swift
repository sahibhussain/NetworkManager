//
//  CustomError.swift
//  SHNetwork
//
//  Created by sahib hussain on 08/06/18.
//  Copyright © 2018 sahib hussain. All rights reserved.
//

import Foundation

public enum SHNetworkError: Error {
    case invalidResponse
    case invalidRequest
    case invalidURL(urlString: String)
    case custom(message: String)
    case unknown
}

extension SHNetworkError: CustomStringConvertible {
    public var description: String { errorDescription ?? "Unknown error" }
}

extension SHNetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Error decoding response data."
        case .invalidRequest: return "Error decoding request data."
        case .invalidURL(let urlString): return "Invalid URL: \(urlString)"
        case .custom(let message): return message
        case .unknown:  return "Unknown error"
        }
    }
}
