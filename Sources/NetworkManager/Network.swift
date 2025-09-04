//
//  SHNetwork.swift
//  SHNetwork
//
//  Created by sahib hussain on 08/06/18.
//  Copyright © 2018 sahib hussain. All rights reserved.
//

import Foundation
import Alamofire
import OSLog

public final class NetworkManager: @unchecked Sendable {
    
    public typealias completion = @Sendable (_ response: Result<[String: Any], Error>) -> Void
    public typealias dataCompletion = @Sendable (_ response: Result<Data, Error>) -> Void
    public typealias codableCompletion<T: Codable> = @Sendable (_ response: Result<T, Error>) -> Void
    public typealias codableResponse<T: Codable> = Result<T, Error>
    
    internal var headers: [String: String]
    internal var session: Session = Session()
    internal var baseURL: String
    
    private let lock = NSLock()
    
    public func getBaseURL() -> String { baseURL }
    public func getGlobalHeaders() -> [String: String] { headers }
    
    
    public init (_ baseURL: String, globalHeaders: [String: String]? = nil, publicKey: URL? = nil, certificate: URL? = nil) {
        self.baseURL = baseURL
        headers = globalHeaders ?? ["Content-Type": "application/json"]
        if let publicKey {
            do {
                let publicKeyData = try Data(contentsOf: publicKey)
                guard let certificate = SecCertificateCreateWithData(nil, publicKeyData as CFData) else {
                    throw NetworkError.invalidCertificate
                }

                var publicKey: SecKey?
                var trust: SecTrust?

                let policy = SecPolicyCreateBasicX509()
                let status = SecTrustCreateWithCertificates(certificate, policy, &trust)
                if status == errSecSuccess, let trust = trust { publicKey = SecTrustCopyKey(trust) }
                
                guard let pinnedPublicKey = publicKey else { throw NetworkError.invalidCertificate }
                let publicKeyTrustEvaluator = PublicKeysTrustEvaluator(keys: [pinnedPublicKey])
                let serverTrustManager = ServerTrustManager(evaluators: [baseURL: publicKeyTrustEvaluator])
                session = Session(serverTrustManager: serverTrustManager)
            } catch {
                let bundleID = Bundle.main.bundleIdentifier ?? "Your App"
                let logger = Logger(subsystem: bundleID, category: "SHNetwork")
                logger.error("Error initialising SHNetwork: \(error)")
            }
        }
        if let certificate {
            do {
                let publicKeyData = try Data(contentsOf: certificate)
                guard let certificate = SecCertificateCreateWithData(nil, publicKeyData as CFData) else {
                    throw NetworkError.invalidCertificate
                }
                
                let publicKeys = [certificate].compactMap { SecCertificateCopyKey($0) }  // Extract public key from the certificate
                let serverTrustManager = ServerTrustManager(evaluators: [baseURL: PublicKeysTrustEvaluator(keys: publicKeys)])
                session = Session(serverTrustManager: serverTrustManager)
            } catch {
                let bundleID = Bundle.main.bundleIdentifier ?? "Your App"
                let logger = Logger(subsystem: bundleID, category: "SHNetwork")
                logger.critical("Error initialising SHNetwork: \(error)")
            }
        }
    }
    
    public func setGlobalHeader(_ key: String, value: String) {
        lock.withLock { [weak self] in
            guard let self else { return }
            headers[key] = value
            headers = sanitizeParam(headers)
        }
    }
    
    public func removeGlobalHeader(_ key: String) {
        lock.withLock { [weak self] in
            guard let self else { return }
            headers[key] = nil
            headers = sanitizeParam(headers)
        }
    }
    
    public func changeBaseURL(_ url: String) {
        lock.withLock { [weak self] in self?.baseURL = url }
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
    
    public func sanitizeParam(_ param: [String: Any]) -> [String: any Sendable] {
        
        var localParam: [String: Any] = [:]
        for (key, _) in param {
            if let value = param[key] as? String, value != "" { localParam[key] = value }
            if let value = param[key] as? Int { localParam[key] = value }
            if let value = param[key] as? Double { localParam[key] = value }
            if let value = param[key] as? Bool { localParam[key] = value }
        }
        return convertToSendableDict(localParam)
        
    }
    
    public func sanitizeParam(_ param: [String: String]) -> [String: String] {
        
        var localParam: [String: String] = [:]
        for (key, _) in param {
            if let value = param[key], value != "" { localParam[key] = value }
        }
        return localParam
        
    }
    
    internal func convertToSendableDict(_ dict: [String: Any]) -> [String: any Sendable] {
        var result: [String: any Sendable] = [:]
        
        for (key, value) in dict {
            switch value {
            case let stringValue as String:
                result[key] = stringValue
            case let intValue as Int:
                result[key] = intValue
            case let doubleValue as Double:
                result[key] = doubleValue
            case let boolValue as Bool:
                result[key] = boolValue
            case let dataValue as Data:
                result[key] = dataValue
            case let urlValue as URL:
                result[key] = urlValue
            default:
                // Convert unknown types to String (which is Sendable)
                result[key] = String(describing: value)
            }
        }
        
        return result
    }
    
    
}
