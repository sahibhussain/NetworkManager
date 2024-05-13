//
//  CustomError.swift
//  SHNetwork
//
//  Created by sahib hussain on 08/06/18.
//  Copyright © 2018 sahib hussain. All rights reserved.
//

import Foundation

enum CustomError: Error {
    case invalidResponse
    case invalidRequest
    case invalidURL(urlString: String)
    case unknown
}

extension CustomError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidResponse: return "Error decoding response data."
        case .invalidRequest: return "Error decoding request data."
        case .invalidURL(let urlString): return "Invalid URL: \(urlString)"
        case .unknown:  return "Unknown error"
        }
    }
}
