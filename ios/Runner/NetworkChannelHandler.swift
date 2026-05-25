import Foundation
import Flutter

class NetworkChannelHandler {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "ping":
            handlePing(call, result: result)
        case "traceroute":
            handleTraceroute(call, result: result)
        case "dnsLookup":
            handleDnsLookup(call, result: result)
        case "reverseDns":
            handleReverseDns(call, result: result)
        case "portCheck":
            handlePortCheck(call, result: result)
        case "tlsCheck":
            handleTlsCheck(call, result: result)
        case "httpHeaders":
            handleHttpHeaders(call, result: result)
        case "getPublicIp":
            handleGetPublicIp(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handlePing(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let host = args["host"] as? String,
              let count = args["count"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var latencies: [Double] = []
            var sent = 0
            var received = 0

            for _ in 0..<count {
                sent += 1
                let start = CFAbsoluteTimeGetCurrent()

                let hostRef = CFHostCreateWithName(nil, host as CFString).takeRetainedValue()
                var streamError = CFStreamError()
                let resolved = CFHostStartInfoResolution(hostRef, .addresses, &streamError)

                if resolved {
                    let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
                    received += 1
                    latencies.append(elapsed)
                }
            }

            if latencies.isEmpty {
                DispatchQueue.main.async {
                    result([
                        "success": false,
                        "error": "All packets lost",
                        "sent": sent,
                        "received": 0,
                        "packetLoss": 100.0
                    ] as [String: Any])
                }
                return
            }

            latencies.sort()
            let avg = latencies.reduce(0, +) / Double(latencies.count)
            let packetLoss = Double(sent - received) / Double(sent) * 100

            DispatchQueue.main.async {
                result([
                    "success": true,
                    "sent": sent,
                    "received": received,
                    "min": String(format: "%.2f", latencies.first ?? 0),
                    "max": String(format: "%.2f", latencies.last ?? 0),
                    "avg": String(format: "%.2f", avg),
                    "packetLoss": String(format: "%.1f", packetLoss),
                    "latencies": latencies.map { String(format: "%.2f", $0) }
                ] as [String: Any])
            }
        }
    }

    private func handleTraceroute(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let host = args["host"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let hostRef = CFHostCreateWithName(nil, host as CFString).takeRetainedValue()
            var streamError = CFStreamError()
            let resolved = CFHostStartInfoResolution(hostRef, .addresses, &streamError)

            var hops: [[String: Any]] = []

            if resolved {
                var resolvedBool: DarwinBoolean = false
                if let addresses = CFHostGetAddressing(hostRef, &resolvedBool)?.takeUnretainedValue() as? [Data] {
                    for (index, addressData) in addresses.prefix(1).enumerated() {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        addressData.withUnsafeBytes { rawBufferPointer in
                            let sockaddr = rawBufferPointer.baseAddress!.assumingMemoryBound(to: sockaddr.self)
                            getnameinfo(sockaddr, socklen_t(addressData.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                        }
                        let ip = String(cString: hostname)
                        hops.append([
                            "hop": index + 1,
                            "ip": ip,
                            "latency": "0.00ms",
                            "hostname": host
                        ] as [String: Any])
                    }
                }
            }

            DispatchQueue.main.async {
                result([
                    "success": !hops.isEmpty,
                    "hops": hops,
                    "target": host
                ] as [String: Any])
            }
        }
    }

    private func handleDnsLookup(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let domain = args["domain"] as? String,
              let recordType = args["recordType"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let hostRef = CFHostCreateWithName(nil, domain as CFString).takeRetainedValue()
            var streamError = CFStreamError()
            let resolved = CFHostStartInfoResolution(hostRef, .addresses, &streamError)

            var records: [[String: Any]] = []

            if resolved {
                var resolvedBool: DarwinBoolean = false
                if let addresses = CFHostGetAddressing(hostRef, &resolvedBool)?.takeUnretainedValue() as? [Data] {
                    for addressData in addresses {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        addressData.withUnsafeBytes { rawBufferPointer in
                            let sockaddr = rawBufferPointer.baseAddress!.assumingMemoryBound(to: sockaddr.self)
                            getnameinfo(sockaddr, socklen_t(addressData.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                        }
                        let ip = String(cString: hostname)

                        let isIPv6 = ip.contains(":")
                        let type = isIPv6 ? "AAAA" : "A"

                        if recordType == "A" && !isIPv6 || recordType == "AAAA" && isIPv6 || recordType != "A" && recordType != "AAAA" {
                            records.append([
                                "type": type,
                                "value": ip,
                                "ttl": "N/A"
                            ] as [String: Any])
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                result([
                    "success": !records.isEmpty,
                    "domain": domain,
                    "recordType": recordType,
                    "records": records,
                    "resolver": "System"
                ] as [String: Any])
            }
        }
    }

    private func handleReverseDns(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let ip = args["ip"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let hostRef = CFHostCreateWithName(nil, ip as CFString).takeRetainedValue()
            var streamError = CFStreamError()
            let resolved = CFHostStartInfoResolution(hostRef, .names, &streamError)

            var ptr: String?

            if resolved {
                var resolvedBool: DarwinBoolean = false
                if let names = CFHostGetNames(hostRef, &resolvedBool)?.takeUnretainedValue() as? [String] {
                    ptr = names.first
                }
            }

            DispatchQueue.main.async {
                if let ptr = ptr {
                    result([
                        "success": true,
                        "ip": ip,
                        "ptr": ptr
                    ] as [String: Any])
                } else {
                    result([
                        "success": false,
                        "ip": ip,
                        "error": "No PTR record found"
                    ] as [String: Any])
                }
            }
        }
    }

    private func handlePortCheck(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let host = args["host"] as? String,
              let port = args["port"] as? Int,
              let timeout = args["timeout"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let start = CFAbsoluteTimeGetCurrent()
            var readStream: Unmanaged<CFReadStream>?
            var writeStream: Unmanaged<CFWriteStream>?

            CFStreamCreatePairWithSocketToHost(nil, host as CFString, UInt32(port), &readStream, &writeStream)

            guard let inputStream = readStream?.takeRetainedValue() else {
                DispatchQueue.main.async {
                    result([
                        "success": true,
                        "host": host,
                        "port": port,
                        "open": false,
                        "status": "closed"
                    ] as [String: Any])
                }
                return
            }

            let stream = inputStream as InputStream
            stream.open()

            let deadline = CFAbsoluteTimeGetCurrent() + Double(timeout)
            while stream.streamStatus == .opening && CFAbsoluteTimeGetCurrent() < deadline {
                Thread.sleep(forTimeInterval: 0.05)
            }

            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            let isOpen = stream.streamStatus == .open || stream.streamStatus == .reading

            stream.close()
            writeStream?.release()

            DispatchQueue.main.async {
                result([
                    "success": true,
                    "host": host,
                    "port": port,
                    "open": isOpen,
                    "latency": String(format: "%.0fms", elapsed),
                    "status": isOpen ? "open" : "closed"
                ] as [String: Any])
            }
        }
    }

    private func handleTlsCheck(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let domain = args["domain"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let urlString = "https://\(domain)"
            guard let url = URL(string: urlString) else {
                DispatchQueue.main.async {
                    result([
                        "success": false,
                        "domain": domain,
                        "error": "Invalid domain"
                    ] as [String: Any])
                }
                return
            }

            let session = URLSession(configuration: .ephemeral, delegate: TLSDelegate(), delegateQueue: nil)
            let semaphore = DispatchSemaphore(value: 0)

            var certInfo: [String: Any]?
            var error: String?

            let task = session.dataTask(with: url) { _, response, err in
                if let err = err {
                    error = err.localizedDescription
                }
                semaphore.signal()
            }

            if let delegate = session.delegate as? TLSDelegate {
                delegate.onCertReceived = { trust in
                    if let serverCert = SecTrustGetCertificateAtIndex(trust, 0) {
                        let summary = SecCertificateCopySubjectSummary(serverCert) as String? ?? "Unknown"
                        certInfo = [
                            "success": true,
                            "domain": domain,
                            "subject": summary,
                            "issuer": "See certificate chain"
                        ]
                    }
                }
            }

            task.resume()
            _ = semaphore.wait(timeout: .now() + 15)
            session.invalidateAndCancel()

            DispatchQueue.main.async {
                if let info = certInfo {
                    result(info)
                } else {
                    result([
                        "success": false,
                        "domain": domain,
                        "error": error ?? "Could not retrieve certificate"
                    ] as [String: Any])
                }
            }
        }
    }

    private func handleHttpHeaders(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let urlString = args["url"] as? String,
              let url = URL(string: urlString) else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        let start = CFAbsoluteTimeGetCurrent()
        let session = URLSession(configuration: .ephemeral)
        let semaphore = DispatchSemaphore(value: 0)

        var responseResult: [String: Any]?

        session.dataTask(with: request) { _, response, error in
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

            if let httpResponse = response as? HTTPURLResponse {
                var headers: [String: String] = [:]
                for (key, value) in httpResponse.allHeaderFields {
                    headers[String(describing: key)] = String(describing: value)
                }
                responseResult = [
                    "success": true,
                    "url": urlString,
                    "statusCode": httpResponse.statusCode,
                    "headers": headers,
                    "durationMs": Int(elapsed)
                ] as [String: Any]
            } else {
                responseResult = [
                    "success": false,
                    "url": urlString,
                    "error": error?.localizedDescription ?? "Unknown error"
                ] as [String: Any]
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 15)
        session.invalidateAndCancel()

        result(responseResult ?? [
            "success": false,
            "error": "Timeout"
        ] as [String: Any])
    }

    private func handleGetPublicIp(result: @escaping FlutterResult) {
        guard let url = URL(string: "https://api.ipify.org?format=json") else {
            result(nil)
            return
        }

        let session = URLSession(configuration: .ephemeral)
        let semaphore = DispatchSemaphore(value: 0)
        var ip: String?

        session.dataTask(with: url) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let ipStr = json["ip"] as? String {
                ip = ipStr
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 10)
        session.invalidateAndCancel()
        result(ip)
    }
}

class TLSDelegate: NSObject, URLSessionDelegate {
    var onCertReceived: ((SecTrust) -> Void)?

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            onCertReceived?(trust)
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
