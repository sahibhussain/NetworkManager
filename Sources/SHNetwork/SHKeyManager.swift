//
//  SHKeyManager.swift
//  SHNetwork
//
//  Created by sahib hussain on 08/06/18.
//  Copyright © 2018 Burning Desire Inclusive. All rights reserved.
//

import Foundation

public class SHKeyManager {
    
    enum KeyError: Error {
        case invalidPassword
        case duplicateEntry
        case unknown(OSStatus)
    }
    
    static let shared = SHKeyManager()
    private init() {}
    
    public func save(_ password: String, accountID: String, domain: String) -> Error? {
        
        guard let passwordData = password.data(using: .utf8) else { return KeyError.invalidPassword }
        
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: domain as AnyObject,
            kSecAttrAccount as String: accountID as AnyObject,
            kSecValueData as String: passwordData as AnyObject
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status != errSecDuplicateItem else {
            return KeyError.duplicateEntry
        }
        
        guard status == errSecSuccess else {
            return KeyError.unknown(status)
        }
        
        return nil
        
    }
    
    public func retrieve(_ accountID: String, domain: String) -> String? {
        
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: domain as AnyObject,
            kSecAttrAccount as String: accountID as AnyObject,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard let returnData = result as? Data else {return nil}
        return String(data: returnData, encoding: .utf8)
        
    }
    
    public func delete(_ accountID: String, domain: String) -> Error? {
        
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: domain as AnyObject,
            kSecAttrAccount as String: accountID as AnyObject
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess else {
            return KeyError.unknown(status)
        }
        
        return nil
        
    }
    
    
    public func generateKeypair() throws -> (privateKey: String, publicKey: String) {
        
        guard let publicTagData = "publicTag".data(using: .utf8), let privateTagData = "privateTag".data(using: .utf8) else {
            throw CustomError.invalidData
        }
        
        let publicAttr: [String: AnyObject] = [
            kSecAttrIsPermanent as String: kCFBooleanTrue,
            kSecAttrApplicationTag as String: publicTagData as AnyObject
        ]
        
        let privateAttr: [String: AnyObject] = [
            kSecAttrIsPermanent as String: kCFBooleanTrue,
            kSecAttrApplicationTag as String: privateTagData as AnyObject
        ]
        
        let keyPairAttr: [String: AnyObject] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA as AnyObject,
            kSecAttrKeySizeInBits as String: 2048 as AnyObject,
            kSecPublicKeyAttrs as String: publicAttr as AnyObject,
            kSecPrivateKeyAttrs as String: privateAttr as AnyObject
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(keyPairAttr as CFDictionary, &error), let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw CustomError.invalidData
        }
        
        if let privateKeyCFData = SecKeyCopyExternalRepresentation(privateKey, &error), let publicKeyCFData = SecKeyCopyExternalRepresentation(publicKey, &error) {
            let privateKeyData = privateKeyCFData as Data
            let publicKeyData = publicKeyCFData as Data
            return (privateKeyData.base64EncodedString(), publicKeyData.base64EncodedString())
        }
        
        throw CustomError.invalidData
        
    }
    
}
