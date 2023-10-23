//
//  CustomError.swift
//  SHNetwork
//
//  Created by sahib hussain on 08/06/18.
//  Copyright © 2018 sahib hussain. All rights reserved.
//

import Foundation

enum CustomError: Error {
    case invalidData
    case invalidURL(urlString: String)
}

extension CustomError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidData: return "Error decoding json data."
        case .invalidURL(let urlString): return "Invalid URL: \(urlString)"
        }
    }
}
