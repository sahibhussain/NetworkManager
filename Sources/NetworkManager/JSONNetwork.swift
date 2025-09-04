//
//  JSONNetwork.swift
//  SHNetwork
//
//  Created by Sahib Hussain on 24/09/24.
//

import Foundation
import Alamofire

// MARK: - Dict completion response -
public extension NetworkManager {
    
    // MARK: - post request
    func sendPostRequest(_ urlExt: String, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping completion) {
        sendRequest(urlExt, method: .post, param: param, shouldSanitise: shouldSanitise, customHeader: customHeader, comp: comp)
    }
    
    func sendPostRequest(_ urlExt: String, param: [String: String], withFile: [String: URL], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        let urlString = baseURL + urlExt
        var localParam = param
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        session.upload(multipartFormData: { (formData) in
            for (key, value) in withFile { formData.append(value, withName: key) }
            for (key, value) in localParam { if let data = value.data(using: .utf8) { formData.append(data, withName: key) } }
        }, to: urlString, headers: .init(localHeaders))
        .responseData(completionHandler: { response in
            switch response.result {
            case .success(let data):
                guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                    comp(.failure(NetworkError.invalidResponse))
                    return
                }
                comp(.success(json))
            case .failure(let error): comp(.failure(error))
            }
        })
        
    }
    
    
    // MARK: - get request
    func sendGetRequest(_ urlExt: String, param: String, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var urlString = baseURL + urlExt + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        session.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(NetworkError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    func sendGetRequest(_ urlExt: String, param: [String: Any], customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var urlString = baseURL + urlExt + "?" + convertToGetParam(param)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        session.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(NetworkError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    func sendGetRequest(with completeUrl: String, param: String, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var urlString = completeUrl + "?" + param
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(NetworkError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    func sendGetRequest(with completeUrl: String, param: [String: Any], customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var urlString = completeUrl + "?" + convertToGetParam(param)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(urlString, method: .get, headers: .init(localHeaders))
            .responseData(completionHandler: { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(NetworkError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            })
        
    }
    
    
    // MARK: - general request
    func sendRequest(_ urlExt: String, method: HTTPMethod, param: [String: Any], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        let urlString = baseURL + urlExt
        var localParam = convertToSendableDict(param)
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
                        
        session.request(urlString, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(localHeaders))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(NetworkError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    func sendRequest(with completeUrl: String, method: HTTPMethod, param: [String: Any], headers: [String: String], shouldSanitise: Bool = false, customHeader: [String: String] = [:], comp: @escaping completion) {
        
        var localParam = convertToSendableDict(param)
        if shouldSanitise { localParam = sanitizeParam(param) }
        let localHeaders = headers.merging(customHeader) { (_, new) in new }
        
        AF.request(completeUrl, method: method, parameters: localParam, encoding: JSONEncoding.default, headers: .init(localHeaders))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(NetworkError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    
    // MARK: - upload request
    func uploadMedia(with completeURL: String, method: HTTPMethod, fileData: Data, customHeader: [String: String], useOnlyCustomHeader: Bool = false, comp: @escaping completion) {
        let localHeaders = useOnlyCustomHeader ? customHeader : headers.merging(customHeader) { (_, new) in new }
        AF.upload(fileData, to: completeURL, method: method, headers: .init(localHeaders))
            .responseData { response in
                switch response.result {
                case .success(let data):
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                        comp(.failure(NetworkError.invalidResponse))
                        return
                    }
                    comp(.success(json))
                case .failure(let error): comp(.failure(error))
                }
            }
    }
    
    
}

