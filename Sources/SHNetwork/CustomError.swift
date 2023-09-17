//
//  File.swift
//  
//
//  Created by Sahib Hussain on 17/03/22.
//

import Foundation

enum CustomError: Error {
    case invalidData
}

extension CustomError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidData:
            return "Error decoding json data."
        }
    }
}
