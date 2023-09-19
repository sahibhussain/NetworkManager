//
//  NetworkHelper.swift
//  SahibHelper
//
//  Created by sahib hussain on 08/06/18.
//  Copyright © 2018 Burning Desire Inclusive. All rights reserved.
//

import UIKit
import Alamofire

public class SHNetwork {
    
    public typealias completion = (_ response: Result<[String: Any], Error>) -> Void
    public typealias codableCompletion<T: Codable> = (_ response: Result<T, Error>) -> Void
    
    public var baseURL: String = ""
    public var headers: [String: String] = [:]
    
    
    public static let shared = SHNetwork()
    private init () {
        headers = ["Content-Type": "application/json"]
    }
    
    public func set(_ header: String, value: String) {
        headers[header] = value
        headers = sanitizeParam(headers)
    }
    
    public func remove(_ header: String) {
        headers[header] = nil
        headers = sanitizeParam(headers)
    }
    
    public func createCustomError(_ message: String?, code: Int = 0) -> Error {
        guard let message = message else {return CustomError.invalidData}
        let customError = NSError(domain:"", code: code, userInfo:[ NSLocalizedDescriptionKey: message])
        return customError as Error
    }
    
    
    // MARK: - post request
    public func sendPostRequest(_ urlExt: String, param: [String: Any], shouldSanitise: Bool = false, comp: @escaping completion) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise {
            localParam = sanitizeParam(param)
        }
        
        AF.request(urlString, method: .post, parameters: localParam, encoding: JSONEncoding.default, headers: .init(headers))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(CustomError.invalidData))
                        return
                    }
                    comp(.success(json))
                    
                case .failure(let error):
                    comp(.failure(error))
                }
            }
        
    }
    
    public func sendPostRequest(_ urlExt: String, param: [String: String], withFile: [String: URL], shouldSanitise: Bool = false, comp: @escaping completion) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise {
            localParam = sanitizeParam(param)
        }
        
        AF.upload(multipartFormData: { (formData) in
            
            for (key, value) in withFile {
                formData.append(value, withName: key)
            }
            
            for (key, value) in localParam {
                let data = value.data(using: .utf8)!
                formData.append(data, withName: key)
            }
            
        }, to: urlString, headers: HTTPHeaders(headers))
        .responseData(completionHandler: { response in
            switch response.result {
            case .success(let data):
                
                guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                    comp(.failure(CustomError.invalidData))
                    return
                }
                comp(.success(json))
                
            case .failure(let error):
                comp(.failure(error))
            }
        })
        
    }
    
    public func sendPostRequest<T: Codable>(_ urlExt: String, param: [String: Any], shouldSanitise: Bool = false, comp: @escaping codableCompletion<T>) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise {
            localParam = sanitizeParam(param)
        }
        
        AF.request(urlString, method: .post, parameters: localParam, encoding: JSONEncoding.default, headers: .init(headers))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    
                    guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                        comp(.failure(CustomError.invalidData))
                        return
                    }
                    comp(.success(json))
                    
                case .failure(let error):
                    comp(.failure(error))
                }
            }
        
    }
    
    public func sendPostRequest<T: Codable>(_ urlExt: String, param: [String: String], withFile: [String: URL], shouldSanitise: Bool = false, comp: @escaping codableCompletion<T>) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise {
            localParam = sanitizeParam(param)
        }
        
        AF.upload(multipartFormData: { (formData) in
            
            for (key, value) in withFile {
                formData.append(value, withName: key)
            }
            
            for (key, value) in localParam {
                let data = value.data(using: .utf8)!
                formData.append(data, withName: key)
            }
            
        }, to: urlString, headers: HTTPHeaders(headers))
        .responseData(completionHandler: { response in
            switch response.result {
            case .success(let data):
                
                guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                    comp(.failure(CustomError.invalidData))
                    return
                }
                comp(.success(json))
                
            case .failure(let error):
                comp(.failure(error))
            }
        })
        
    }
    
    
    // MARK: - get request
    public func sendGetRequest(_ urlExt: String, param: String, comp: @escaping completion) {
        
        var urlString = baseURL + urlExt + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        
        AF.request(urlString, method: .get, headers: HTTPHeaders(headers))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(CustomError.invalidData))
                        return
                    }
                    comp(.success(json))
                    
                case .failure(let error):
                    comp(.failure(error))
                }
            })
        
    }
    
    public func sendGetRequest(_ urlExt: String, param: [String: Any], comp: @escaping completion) {
        
        var urlString = baseURL + urlExt + "?" + convertToGetParam(param)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        
        AF.request(urlString, method: .get, headers: HTTPHeaders(headers))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(CustomError.invalidData))
                        return
                    }
                    comp(.success(json))
                    
                case .failure(let error):
                    comp(.failure(error))
                }
            })
        
    }
    
    public func sendGetRequest(with completeUrl: String, param: String, comp: @escaping completion) {
        
        var urlString = completeUrl + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        
        AF.request(urlString, method: .get, headers: HTTPHeaders(headers))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(CustomError.invalidData))
                        return
                    }
                    comp(.success(json))
                    
                case .failure(let error):
                    comp(.failure(error))
                }
            })
        
    }
    
    public func sendGetRequest(with completeUrl: String, param: [String: Any], comp: @escaping completion) {
        
        var urlString = completeUrl + "?" + convertToGetParam(param)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        
        AF.request(urlString, method: .get, headers: HTTPHeaders(headers))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(CustomError.invalidData))
                        return
                    }
                    comp(.success(json))
                    
                case .failure(let error):
                    comp(.failure(error))
                }
            })
        
    }
    
    public func sendGetRequest<T: Codable>(_ urlExt: String, param: String, comp: @escaping codableCompletion<T>) {
        
        var urlString = baseURL + urlExt + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        
        AF.request(urlString, method: .get, headers: HTTPHeaders(headers))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    
                    guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                        comp(.failure(CustomError.invalidData))
                        return
                    }
                    comp(.success(json))
                    
                case .failure(let error):
                    comp(.failure(error))
                }
            })
        
    }
    
    public func sendGetRequest<T: Codable>(_ urlExt: String, param: [String: Any], comp: @escaping codableCompletion<T>) {
        
        var urlString = baseURL + urlExt + "?" + convertToGetParam(param)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        
        AF.request(urlString, method: .get, headers: HTTPHeaders(headers))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    
                    guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                        comp(.failure(CustomError.invalidData))
                        return
                    }
                    comp(.success(json))
                    
                case .failure(let error):
                    comp(.failure(error))
                }
            })
        
    }
    
    public func sendGetRequest<T: Codable>(with completeUrl: String, param: String, comp: @escaping codableCompletion<T>) {
        
        var urlString = completeUrl + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        
        AF.request(urlString, method: .get, headers: HTTPHeaders(headers))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    
                    guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                        comp(.failure(CustomError.invalidData))
                        return
                    }
                    comp(.success(json))
                    
                case .failure(let error):
                    comp(.failure(error))
                }
            })
        
    }
    
    public func sendGetRequest<T: Codable>(with completeUrl: String, param: [String: Any], comp: @escaping codableCompletion<T>) {
        
        var urlString = completeUrl + "?" + convertToGetParam(param)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        
        AF.request(urlString, method: .get, headers: HTTPHeaders(headers))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    
                    guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                        comp(.failure(CustomError.invalidData))
                        return
                    }
                    comp(.success(json))
                    
                case .failure(let error):
                    comp(.failure(error))
                }
            })
        
    }
    
    
    // MARK: - general request
    public func sendRequest(_ urlExt: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, comp: @escaping completion) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise {
            localParam = sanitizeParam(param)
        }
        
                        
        AF.request(urlString, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(headers))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(CustomError.invalidData))
                        return
                    }
                    comp(.success(json))
                    
                case .failure(let error):
                    comp(.failure(error))
                }
            }
    }
    
    public func sendRequest(with completeUrl: String, method: HTTPMethod, param: [String: Any], headers: [String: String], shouldSanitise: Bool = false, comp: @escaping completion) {
        
        var localParam = param
        if shouldSanitise {
            localParam = sanitizeParam(param)
        }
        
        
        AF.request(completeUrl, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(headers))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(CustomError.invalidData))
                        return
                    }
                    comp(.success(json))
                    
                case .failure(let error):
                    comp(.failure(error))
                }
            }
    }
    
    public func sendRequest<T: Codable>(_ urlExt: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, comp: @escaping codableCompletion<T>) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise {
            localParam = sanitizeParam(param)
        }
        
                        
        AF.request(urlString, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(headers))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    
                    guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                        comp(.failure(CustomError.invalidData))
                        return
                    }
                    comp(.success(json))
                    
                case .failure(let error):
                    comp(.failure(error))
                }
            }
    }
    
    public func sendRequest<T: Codable>(with completeUrl: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, headers: [String: String], comp: @escaping codableCompletion<T>) {
        
        var localParam = param
        if shouldSanitise {
            localParam = sanitizeParam(param)
        }
        
        
        AF.request(completeUrl, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(headers))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    
                    guard let json = try? JSONDecoder().decode(T.self, from: data) else {
                        comp(.failure(CustomError.invalidData))
                        return
                    }
                    comp(.success(json))
                    
                case .failure(let error):
                    comp(.failure(error))
                }
            }
    }
    
    
    // MARK: - upload request
    public func uploadMedia(with completeURL: String, method: HTTPMethod, fileData: Data, headers: [String: String], comp: @escaping (Bool) -> Void) {
        
        AF.upload(fileData, to: completeURL, method: method, headers: .init(headers))
            .responseData { response in
                comp(response.response?.statusCode == 200)
            }
        
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
        for (key, value) in param {
            if param[key] as? String != nil && param[key] as? String != "" {
                localParam[key] = value
            }
            else if param[key] as? Int != nil {
                localParam[key] = value
            }
        }
        
        return localParam
        
    }
    
    public func sanitizeParam(_ param: [String: String]) -> [String: String] {
        
        var localParam: [String: String] = [:]
        for (key, value) in param {
            if param[key] != nil && param[key] != "" {
                localParam[key] = value
            }
        }
        
        return localParam
        
    }
    
    
}

