//
//  CodableNetwork.swift
//  SHNetwork
//
//  Created by Sahib Hussain on 24/09/24.
//

import Foundation
import Alamofire

// MARK: - Codable completion response -
public extension NetworkManager {
    
    // MARK: - post request
    func sendPostRequest<T: Codable & Sendable>(_ urlExt: String, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        sendRequest(urlExt, method: .post, param: param, shouldSanitise: shouldSanitise, customHeader: customHeader, comp: comp)
    }
    
    func sendPostRequest<T: Codable & Sendable>(_ urlExt: String, param: [String: String], withFile: [String: URL], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        session.upload(multipartFormData: { (formData) in
            for (key, value) in withFile { formData.append(value, withName: key) }
            for (key, value) in localParam { if let data = value.data(using: .utf8) { formData.append(data, withName: key) } }
        }, to: urlString, headers: HTTPHeaders(localHeaders))
        .responseDecodable(of: T.self) { response in
            switch response.result {
            case .success(let result): comp(.success(result))
            case .failure(let error): comp(.failure(error))
            }
        }
    }
    
    
    // MARK: - get request
    func sendGetRequest<T: Codable & Sendable>(_ urlExt: String, param: [String: Any], customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        sendGetRequest(urlExt, param: convertToGetParam(param), customHeader: customHeader, comp: comp)
    }
    
    func sendGetRequest<T: Codable & Sendable>(_ urlExt: String, param: String, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        
        var urlString = baseURL + urlExt + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        session.request(urlString, method: .get, headers: .init(localHeaders))
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let result): comp(.success(result))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    func sendGetRequest<T: Codable & Sendable>(with completeUrl: String, param: [String: Any], customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        sendGetRequest(with: completeUrl, param: convertToGetParam(param), customHeader: customHeader, comp: comp)
    }
    
    func sendGetRequest<T: Codable & Sendable>(with completeUrl: String, param: String, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        
        var urlString = completeUrl + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let result): comp(.success(result))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    
    // MARK: - general request
    func sendRequest<T: Codable & Sendable>(_ urlExt: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping codableCompletion<T>) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
                        
        session.request(urlString, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(localHeaders))
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let result): comp(.success(result))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    func sendRequest<T: Codable & Sendable>(with completeUrl: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], headers: [String: String], comp: @escaping codableCompletion<T>) {
        
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(completeUrl, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(localHeaders))
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let result): comp(.success(result))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    
    // MARK: - upload request
    func uploadMedia<T: Codable & Sendable>(with completeURL: String, method: HTTPMethod, fileData: Data, customHeader: [String: String], useOnlyCustomHeader: Bool = false, comp: @escaping codableCompletion<T>) {
        let localHeaders = useOnlyCustomHeader ? customHeader : headers.merging(customHeader) { (_, new) in new }
        AF.upload(fileData, to: completeURL, method: method, headers: .init(localHeaders))
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let result): comp(.success(result))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
}

