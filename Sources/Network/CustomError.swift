//
//  CustomError.swift
//  SHNetwork
//
//  Created by sahib hussain on 08/06/18.
//  Copyright © 2018 sahib hussain. All rights reserved.
//

import Foundation

public enum NetworkError: Error {
    case invalidResponse
    case invalidRequest
    case invalidCertificate
    case invalidURL(urlString: String, code: Int = 400)
    case custom(message: String, code: Int = 400)
    case unknown
}

extension NetworkError: CustomStringConvertible {
    
    public var description: String { errorDescription ?? "Unknown error" }
    
    public var errorCode: Int {
        switch self {
        case .invalidResponse: return 500
        case .invalidRequest: return 400
        case .invalidCertificate: return 401
        case .invalidURL(_, let code): return code
        case .custom(_, let code): return code
        case .unknown:  return 400
        }
    }
    
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Error decoding response data."
        case .invalidRequest: return "Error decoding request data."
        case .invalidCertificate: return "Invalid certificate."
        case .invalidURL(let urlString, _): return "Invalid URL: \(urlString)"
        case .custom(let message, _): return message
        case .unknown:  return "Unknown error"
        }
    }
}


extension Error {
    public var shNetworkError: NetworkError? {
        self as? NetworkError
    }
}
