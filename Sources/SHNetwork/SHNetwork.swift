//
//  SHNetwork.swift
//  SHNetwork
//
//  Created by sahib hussain on 08/06/18.
//  Copyright © 2018 sahib hussain. All rights reserved.
//

import Foundation
import Alamofire

public class SHNetwork {
    
    public typealias completion = (_ response: Result<[String: Any], Error>) -> Void
    public typealias codableCompletion<T: Codable> = (_ response: Result<T, Error>) -> Void
    
    private(set) var baseURL: String = ""
    private(set) var headers: [String: String] = [:]
    
    
//        .responseDecodable(of: T.self, completionHandler: { response in
//            switch response.result {
//            case .success(let result): comp(.success(result))
//            case .failure(let error): comp(.failure(error))
//            }
//        })
    
    public static let shared = SHNetwork()
    private init () {
        headers = ["Content-Type": "application/json"]
    }
    
    public func initialise(_ baseURL: String, globalHeaders: [String: String] = [:]) {
        self.baseURL = baseURL
        self.headers = globalHeaders
    }
    
    public func setGlobalHeader(_ key: String, value: String) {
        headers[key] = value
        headers = sanitizeParam(headers)
    }
    
    public func removeGlobalHeader(_ key: String) {
        headers[key] = nil
        headers = sanitizeParam(headers)
    }
    
    public func createCustomError(_ message: String?, code: Int = 0) -> Error {
        guard let message = message else {return CustomError.unknown}
        let customError = NSError(domain:"", code: code, userInfo:[ NSLocalizedDescriptionKey: message])
        return customError as Error
    }
    
    
    // MARK: - post request
    public func sendPostRequest(_ urlExt: String, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping completion) {
        sendRequest(urlExt, method: .post, param: param, shouldSanitise: shouldSanitise, customHeader: customHeader, comp: comp)
    }
    
    public func sendPostRequest(_ urlExt: String, param: [String: String], withFile: [String: URL], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.upload(multipartFormData: { (formData) in
            for (key, value) in withFile { formData.append(value, withName: key) }
            for (key, value) in localParam { if let data = value.data(using: .utf8) { formData.append(data, withName: key) } }
        }, to: urlString, headers: .init(localHeaders))
        .responseData(completionHandler: { response in
            switch response.result {
            case .success(let data):
                guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                    comp(.failure(CustomError.invalidResponse))
                    return
                }
                comp(.success(json))
            case .failure(let error): comp(.failure(error))
            }
        })
        
    }
    
    public func sendCodablePostRequest<T: Codable>(_ urlExt: String, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        sendCodableRequest(urlExt, method: .post, param: param, shouldSanitise: shouldSanitise, customHeader: customHeader, comp: comp)
    }
    
    public func sendCodablePostRequest<T: Codable>(_ urlExt: String, param: [String: String], withFile: [String: URL], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.upload(multipartFormData: { (formData) in
            for (key, value) in withFile { formData.append(value, withName: key) }
            for (key, value) in localParam { if let data = value.data(using: .utf8) { formData.append(data, withName: key) } }
        }, to: urlString, headers: HTTPHeaders(headers))
        .responseData(completionHandler: { response in
            switch response.result {
            case .success(let data):
                guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                    comp(.failure(CustomError.invalidResponse))
                    return
                }
                comp(.success(json))
            case .failure(let error): comp(.failure(error))
            }
        })
        
    }
    
    
    // MARK: - get request
    public func sendGetRequest(_ urlExt: String, param: String, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var urlString = baseURL + urlExt + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(CustomError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    public func sendGetRequest(_ urlExt: String, param: [String: Any], customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var urlString = baseURL + urlExt + "?" + convertToGetParam(param)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(CustomError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    public func sendGetRequest(with completeUrl: String, param: String, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var urlString = completeUrl + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(CustomError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    public func sendGetRequest(with completeUrl: String, param: [String: Any], customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var urlString = completeUrl + "?" + convertToGetParam(param)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(CustomError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    public func sendCodableGetRequest<T: Codable>(_ urlExt: String, param: String, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        
        var urlString = baseURL + urlExt + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                        comp(.failure(CustomError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    public func sendCodableGetRequest<T: Codable>(_ urlExt: String, param: [String: Any], customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        
        var urlString = baseURL + urlExt + "?" + convertToGetParam(param)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: HTTPHeaders(headers))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                        comp(.failure(CustomError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    public func sendCodableGetRequest<T: Codable>(with completeUrl: String, param: String, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        
        var urlString = completeUrl + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                        comp(.failure(CustomError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    public func sendCodableGetRequest<T: Codable>(with completeUrl: String, param: [String: Any], customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        
        var urlString = completeUrl + "?" + convertToGetParam(param)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: HTTPHeaders(headers))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                        comp(.failure(CustomError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    
    // MARK: - general request
    public func sendRequest(_ urlExt: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
                        
        AF.request(urlString, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(localHeaders))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(CustomError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    public func sendRequest(with completeUrl: String, method: HTTPMethod, param: [String: Any], headers: [String: String], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(completeUrl, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(headers))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(CustomError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    public func sendCodableRequest<T: Codable>(_ urlExt: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
                        
        AF.request(urlString, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(headers))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                        comp(.failure(CustomError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    public func sendCodableRequest<T: Codable>(with completeUrl: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], headers: [String: String], comp: @escaping codableCompletion<T>) {
        
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(completeUrl, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(headers))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                        comp(.failure(CustomError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    
    // MARK: - upload request
    public func uploadMedia(with completeURL: String, method: HTTPMethod, fileData: Data, customHeader: [String: String], useOnlyCustomHeader: Bool = false, comp: @escaping (Bool) -> Void) {
        let localHeaders = useOnlyCustomHeader ? customHeader : headers.merging(customHeader) { (_, new) in new }
        AF.upload(fileData, to: completeURL, method: method, headers: .init(localHeaders))
            .responseData { response in comp(response.response?.statusCode == 200) }
    }
    
    
    // MARK: - parameter related
    public func jsonToString(_ json: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {return nil}
        return String(data: data, encoding: .utf8)
    }
    
    public func convertToGetParam(_ param: [String: Any]) -> String {
        
        var localParam = ""
        for (key, value) in param {
            let stringValue = "\(value)"
            if stringValue != "" {
                localParam += key + "=" + stringValue + "&"
            }
        }
        
        return String(localParam.dropLast())
        
    }
    
    public func sanitizeParam(_ param: [String: Any]) -> [String: Any] {
        
        var localParam: [String: Any] = [:]
        for (key, _) in param {
            if let value = param[key] as? String, value != "" { localParam[key] = value }
            if let value = param[key] as? Int { localParam[key] = value }
            if let value = param[key] as? Double { localParam[key] = value }
            if let value = param[key] as? Bool { localParam[key] = value }
        }
        return localParam
        
    }
    
    public func sanitizeParam(_ param: [String: String]) -> [String: String] {
        
        var localParam: [String: String] = [:]
        for (key, _) in param {
            if let value = param[key], value != "" { localParam[key] = value }
        }
        return localParam
        
    }
    
    
}

