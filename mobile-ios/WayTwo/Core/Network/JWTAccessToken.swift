import Foundation

enum JWTAccessToken {
    static func subject(_ token: String) -> String? {
        let segments = token.split(separator: ".")
        guard segments.count == 3, let payloadData = base64URLDecode(String(segments[1])) else {
            return nil
        }
        guard
            let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
            let subject = json["sub"] as? String
        else {
            return nil
        }
        return subject
    }

    private static func base64URLDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddingLength = 4 - (base64.count % 4)
        if paddingLength < 4 {
            base64 += String(repeating: "=", count: paddingLength)
        }
        return Data(base64Encoded: base64)
    }
}
