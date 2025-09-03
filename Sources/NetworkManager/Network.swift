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

open class NetworkManager {
    
    public typealias completion = (_ response: Result<[String: Any], Error>) -> Void
    public typealias dataCompletion = (_ response: Result<Data, Error>) -> Void
    public typealias codableCompletion<T: Codable> = (_ response: Result<T, Error>) -> Void
    
    public typealias codableResponse<T: Codable> = Result<T, Error>
    
    internal var baseURL: String = ""
    internal var headers: [String: String] = [:]
    internal var session: Session = Session()
    
    public func getBaseURL() -> String { baseURL }
    public func getGlobalHeaders() -> [String: String] { headers }
    
    
    public static let shared = NetworkManager()
    
    public init () {
        headers = ["Content-Type": "application/json"]
    }
    
    public func initialise(_ baseURL: String, globalHeaders: [String: String]? = nil, publicKey: URL? = nil, certificate: URL? = nil) {
        self.baseURL = baseURL
        if let globalHeaders { self.headers = globalHeaders }
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
        headers[key] = value
        headers = sanitizeParam(headers)
    }
    
    public func removeGlobalHeader(_ key: String) {
        headers[key] = nil
        headers = sanitizeParam(headers)
    }
    
    @available(*, deprecated, message: "Use SHNetworkError.custom(message:code:) instead")
    public func createCustomError(_ message: String?, code: Int = 0) -> Error {
        guard let message = message else {return NetworkError.unknown}
        let customError = NSError(domain:"", code: code, userInfo:[ NSLocalizedDescriptionKey: message])
        return customError as Error
    }
    
    
    // MARK: - parameter related
    @available(*, deprecated, message: "Use your own JSON serialization instead")
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
