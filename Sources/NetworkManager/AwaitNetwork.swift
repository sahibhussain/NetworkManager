//
//  AwaitNetwork.swift
//  SHNetwork
//
//  Created by Sahib Hussain on 14/06/25.
//

import Foundation
import Alamofire

// MARK: - Codable completion response -
public extension NetworkManager {
    
    // MARK: - post request
    func sendPostRequest<T: Codable & Sendable>(_ urlExt: String, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:]) async throws -> T {
        try await sendRequest(urlExt, method: .post, param: param, shouldSanitise: shouldSanitise, customHeader: customHeader)
    }
    
    func sendPostRequest<T: Codable & Sendable>(_ urlExt: String, param: [String: String], withFile: [String: URL], shouldSanitise: Bool = false, customHeader: [String: String] = [:]) async throws -> T {
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(multipartFormData: { (formData) in
                for (key, value) in withFile { formData.append(value, withName: key) }
                for (key, value) in localParam { if let data = value.data(using: .utf8) { formData.append(data, withName: key) } }
            }, to: urlString, headers: HTTPHeaders(localHeaders))
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let result): continuation.resume(returning: result)
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
        }
    }
    
    
    // MARK: - get request
    func sendGetRequest<T: Codable & Sendable>(_ urlExt: String, param: [String: Any], customHeader: [String: String] = [:]) async throws -> T {
        return try await sendGetRequest(urlExt, param: convertToGetParam(param), customHeader: customHeader)
    }
    
    func sendGetRequest<T: Codable & Sendable>(_ urlExt: String, param: String, customHeader: [String: String] = [:]) async throws -> T {
        var urlString = baseURL + urlExt + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        return try await withCheckedThrowingContinuation { continuation in
            session.request(urlString, method: .get, headers: .init(localHeaders))
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let result): continuation.resume(returning: result)
                    case .failure(let error): continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    func sendGetRequest<T: Codable & Sendable>(with completeUrl: String, param: [String: Any], customHeader: [String: String] = [:]) async throws -> T {
        return try await sendGetRequest(with: completeUrl, param: convertToGetParam(param), customHeader: customHeader)
    }
    
    func sendGetRequest<T: Codable & Sendable>(with completeUrl: String, param: String, customHeader: [String: String] = [:]) async throws -> T {
        
        var urlString = completeUrl + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(urlString, method: .get, headers: .init(localHeaders))
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let result): continuation.resume(returning: result)
                    case .failure(let error): continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    
    // MARK: - general request
    func sendRequest<T: Codable & Sendable>(_ urlExt: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:]) async throws -> T {
        let urlString = baseURL + urlExt
        var localParam = convertToSendableDict(param)
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        return try await withCheckedThrowingContinuation { continuation in
            session.request(urlString, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(localHeaders))
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let result): continuation.resume(returning: result)
                    case .failure(let error): continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    func sendRequest<T: Codable & Sendable>(with completeUrl: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], headers: [String: String]) async throws -> T {
        var localParam = convertToSendableDict(param)
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(completeUrl, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(localHeaders))
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let result): continuation.resume(returning: result)
                    case .failure(let error): continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    
    // MARK: - upload request
    func uploadMedia<T: Codable & Sendable>(with completeURL: String, method: HTTPMethod, fileData: Data, customHeader: [String: String], useOnlyCustomHeader: Bool = false) async throws -> T {
        let localHeaders = useOnlyCustomHeader ? customHeader : headers.merging(customHeader) { (_, new) in new }
        return try await withCheckedThrowingContinuation { continuation in
            AF.upload(fileData, to: completeURL, method: method, headers: .init(localHeaders))
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let result): continuation.resume(returning: result)
                    case .failure(let error): continuation.resume(throwing: error)
                    }
                }
        }
    }
    
}

