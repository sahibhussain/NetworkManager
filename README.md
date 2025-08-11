
# Network
A pure Swift library to perform all network functions with ease

## Overview

Network is a lightweight, Swift-native networking library designed to simplify HTTP requests and API interactions in iOS applications. Built with modern Swift principles, it provides a clean, intuitive interface for common networking operations while maintaining flexibility for advanced use cases.

Key features:
- Simple, singleton-based API for quick setup
- Built-in SSL pinning support for enhanced security
- Global header management
- Support for multiple response types (Data, Dictionary, Codable)
- Convenient helper methods for GET and POST requests
- Comprehensive error handling with Swift's Result type

## Installation

### Swift Package Manager (SPM)

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

**If using in Application:**

1. Open your Xcode project
2. Go to File > Swift Packages > Add Package Dependency
3. Add `https://github.com/sahibhussain/Network.git`
4. Select "Up to Next Major" with "1.1.0"

**If using in Package:**

Once you have your Swift package set up, adding Network as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/sahibhussain/Network.git", .upToNextMajor(from: "1.1.0"))
]
```

Then add the Network product to your target dependencies:

```swift
.product(name: "Network", package: "Network")
```

## Usage

### Initialization

Most applications have a single API base URL that is used throughout the application. For these cases, we provide a simple initialization method.

#### Parameters:
- `baseURL: String`: The base URL of the API path
- `globalHeaders: [String: String]?`: Global headers to include with all requests (optional)
- `publicKey: URL?`: Public key file URL for SSL pinning (optional)
- `certificate: URL?`: Certificate file URL for SSL pinning (optional)

```swift
// Basic initialization
Network.shared.initialise("https://api.example.com", globalHeaders: ["Content-Type": "application/json"])

// With SSL pinning
let publicKeyURL = Bundle.main.url(forResource: "public_key", withExtension: "der")
let certificateURL = Bundle.main.url(forResource: "certificate", withExtension: "cer")

Network.shared.initialise(
    "https://api.example.com", 
    globalHeaders: ["Content-Type": "application/json", "Accept": "application/json"],
    publicKey: publicKeyURL,
    certificate: certificateURL
)
```

#### Managing Global Headers

Add or update a global header:

```swift
Network.shared.setGlobalHeader("Authorization", value: "Bearer your-token-here")
Network.shared.setGlobalHeader("User-Agent", value: "YourApp/1.0")
```

Remove a global header:

```swift
Network.shared.removeGlobalHeader("Authorization")
```

### Making API Calls

The library supports multiple response types:
- `Result<Data, Error>`: Raw data response
- `Result<[String: Any], Error>`: JSON dictionary response
- `Result<T: Codable, Error>`: Decoded model response

#### General Request Method

The `sendRequest` method is the most flexible option for making API calls.

##### Parameters:
- `urlExt: String`: The API endpoint path (will be appended to base URL)
- `method: HTTPMethod`: The HTTP method (.GET, .POST, .PUT, .DELETE, etc.)
- `param: [String: Any]`: Request parameters (optional)
- `shouldSanitise: Bool`: Whether to sanitize the parameters (default: true)
- `customHeader: [String: String]`: Additional headers for this specific request (optional)

```swift
Network.shared.sendRequest(
    "/api/v1/login",
    method: .POST,
    param: ["username": "john_doe", "password": "secure_password"],
    shouldSanitise: false,
    customHeader: ["Device-ID": "1234-5678-9012"]
) { (response: Result<[String: Any], Error>) in
    switch response {
    case .success(let data):
        print("Login successful: \(data)")
        // Handle successful response
    case .failure(let error):
        print("Login failed: \(error.localizedDescription)")
        // Handle error
    }
}
```

#### GET Request Helper

For convenience, use the dedicated GET request method:

##### Parameters:
- `urlExt: String`: The API endpoint path
- `param: [String: Any]`: Query parameters (optional)
- `customHeader: [String: String]`: Additional headers (optional)

```swift
Network.shared.sendGetRequest(
    "/api/v1/users",
    param: ["page": 1, "limit": 10],
    customHeader: ["Cache-Control": "no-cache"]
) { (response: Result<Data, Error>) in
    switch response {
    case .success(let data):
        // Process the raw data or decode to your model
        do {
            let users = try JSONDecoder().decode([User].self, from: data)
            print("Fetched \(users.count) users")
        } catch {
            print("Decoding error: \(error)")
        }
    case .failure(let error):
        print("Request failed: \(error.localizedDescription)")
    }
}
```

#### POST Request Helper

For POST requests, use the dedicated helper method:

##### Parameters:
- `urlExt: String`: The API endpoint path
- `param: [String: Any]`: Request body parameters
- `shouldSanitise: Bool`: Whether to sanitize the parameters
- `customHeader: [String: String]`: Additional headers (optional)

```swift
let userData = [
    "name": "John Doe",
    "email": "john@example.com",
    "age": 30
]

Network.shared.sendPostRequest(
    "/api/v1/users",
    param: userData,
    shouldSanitise: true,
    customHeader: ["Content-Type": "application/json"]
) { (response: Result<User, Error>) in
    switch response {
    case .success(let user):
        print("User created successfully: \(user.name)")
        // Navigate to next screen or update UI
    case .failure(let error):
        print("Failed to create user: \(error.localizedDescription)")
        // Show error message to user
    }
}
```

### Error Handling Best Practices

When working with the Network library, always handle both success and failure cases:

```swift
Network.shared.sendRequest("/api/v1/data", method: .GET) { (response: Result<DataModel, Error>) in
    DispatchQueue.main.async {
        switch response {
        case .success(let data):
            // Update UI with successful data
            self.updateUI(with: data)
        case .failure(let error):
            // Handle specific error types
            if let networkError = error as? URLError {
                switch networkError.code {
                case .notConnectedToInternet:
                    self.showNoInternetAlert()
                case .timedOut:
                    self.showTimeoutAlert()
                default:
                    self.showGenericErrorAlert(error.localizedDescription)
                }
            } else {
                self.showGenericErrorAlert(error.localizedDescription)
            }
        }
    }
}
```

### Security Considerations

When using SSL pinning, ensure your certificates and public keys are:
- Stored securely in your app bundle
- Updated before expiration
- Validated against your server's actual certificates

```swift
// Example of implementing certificate validation
func validateSSLPinning() -> Bool {
    guard let publicKeyURL = Bundle.main.url(forResource: "api_public_key", withExtension: "der"),
          let certificateURL = Bundle.main.url(forResource: "api_certificate", withExtension: "cer") else {
        print("SSL pinning files not found in bundle")
        return false
    }
    
    // Initialize with SSL pinning
    Network.shared.initialise(
        "https://secure-api.example.com",
        globalHeaders: ["Content-Type": "application/json"],
        publicKey: publicKeyURL,
        certificate: certificateURL
    )
    
    return true
}
```

## Contact

Follow and contact me on [X (Twitter)](https://x.com/Sahib_hussain0). 

For issues and feature requests:
- [Open an issue](https://github.com/sahibhussain/Network/issues/new) on GitHub
- Pull requests are warmly welcomed

## License

[Add your license information here]

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## Changelog

### Version 1.1.0
- Added SSL pinning support
- Improved error handling
- Enhanced documentation

### Version 1.0.0
- Initial release
- Basic networking functionality
- Global header management