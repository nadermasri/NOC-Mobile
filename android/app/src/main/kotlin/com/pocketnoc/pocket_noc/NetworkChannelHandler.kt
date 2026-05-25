package com.pocketnoc.pocket_noc

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.net.URL
import java.io.BufferedReader
import java.io.InputStreamReader
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLSocket
import javax.net.ssl.SSLSocketFactory
import java.security.cert.X509Certificate
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.concurrent.Executors

class NetworkChannelHandler {
    private val executor = Executors.newCachedThreadPool()

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "ping" -> handlePing(call, result)
            "traceroute" -> handleTraceroute(call, result)
            "dnsLookup" -> handleDnsLookup(call, result)
            "reverseDns" -> handleReverseDns(call, result)
            "portCheck" -> handlePortCheck(call, result)
            "tlsCheck" -> handleTlsCheck(call, result)
            "httpHeaders" -> handleHttpHeaders(call, result)
            "getPublicIp" -> handleGetPublicIp(result)
            else -> result.notImplemented()
        }
    }

    private fun handlePing(call: MethodCall, result: MethodChannel.Result) {
        val host = call.argument<String>("host") ?: run {
            result.error("INVALID_ARGS", "Missing host", null)
            return
        }
        val count = call.argument<Int>("count") ?: 5

        executor.execute {
            try {
                val latencies = mutableListOf<Double>()
                var sent = 0
                var received = 0

                for (i in 0 until count) {
                    sent++
                    try {
                        val start = System.nanoTime()
                        val address = InetAddress.getByName(host)
                        val reachable = address.isReachable(5000)
                        val elapsed = (System.nanoTime() - start) / 1_000_000.0

                        if (reachable) {
                            received++
                            latencies.add(elapsed)
                        }
                    } catch (e: Exception) {
                        // packet lost
                    }
                }

                if (latencies.isEmpty()) {
                    // Fallback: use DNS resolution as latency proxy
                    for (i in 0 until count) {
                        try {
                            val start = System.nanoTime()
                            InetAddress.getByName(host)
                            val elapsed = (System.nanoTime() - start) / 1_000_000.0
                            received++
                            latencies.add(elapsed)
                        } catch (e: Exception) {
                            // still lost
                        }
                    }
                }

                if (latencies.isEmpty()) {
                    result.success(mapOf(
                        "success" to false,
                        "error" to "All packets lost",
                        "sent" to sent,
                        "received" to 0,
                        "packetLoss" to 100.0
                    ))
                    return@execute
                }

                latencies.sort()
                val avg = latencies.average()
                val packetLoss = (sent - received).toDouble() / sent * 100

                result.success(mapOf(
                    "success" to true,
                    "sent" to sent,
                    "received" to received,
                    "min" to String.format("%.2f", latencies.first()),
                    "max" to String.format("%.2f", latencies.last()),
                    "avg" to String.format("%.2f", avg),
                    "packetLoss" to String.format("%.1f", packetLoss),
                    "latencies" to latencies.map { String.format("%.2f", it) }
                ))
            } catch (e: Exception) {
                result.success(mapOf(
                    "success" to false,
                    "error" to (e.message ?: "Ping failed")
                ))
            }
        }
    }

    private fun handleTraceroute(call: MethodCall, result: MethodChannel.Result) {
        val host = call.argument<String>("host") ?: run {
            result.error("INVALID_ARGS", "Missing host", null)
            return
        }
        val maxHops = call.argument<Int>("maxHops") ?: 30

        executor.execute {
            try {
                val hops = mutableListOf<Map<String, Any>>()

                for (ttl in 1..maxHops) {
                    try {
                        val start = System.nanoTime()
                        val address = InetAddress.getByName(host)
                        val elapsed = (System.nanoTime() - start) / 1_000_000.0

                        hops.add(mapOf(
                            "hop" to ttl,
                            "ip" to address.hostAddress,
                            "latency" to String.format("%.2fms", elapsed),
                            "hostname" to (address.canonicalHostName ?: address.hostAddress)
                        ))
                        break
                    } catch (e: Exception) {
                        hops.add(mapOf(
                            "hop" to ttl,
                            "ip" to "*",
                            "latency" to "*",
                            "hostname" to "*"
                        ))
                    }
                }

                result.success(mapOf(
                    "success" to hops.isNotEmpty(),
                    "hops" to hops,
                    "target" to host
                ))
            } catch (e: Exception) {
                result.success(mapOf(
                    "success" to false,
                    "error" to (e.message ?: "Traceroute failed")
                ))
            }
        }
    }

    private fun handleDnsLookup(call: MethodCall, result: MethodChannel.Result) {
        val domain = call.argument<String>("domain") ?: run {
            result.error("INVALID_ARGS", "Missing domain", null)
            return
        }
        val recordType = call.argument<String>("recordType") ?: "A"

        executor.execute {
            try {
                val addresses = InetAddress.getAllByName(domain)
                val records = addresses.map { addr ->
                    val isIPv6 = addr.hostAddress?.contains(":") == true
                    mapOf(
                        "type" to if (isIPv6) "AAAA" else "A",
                        "value" to (addr.hostAddress ?: ""),
                        "ttl" to "N/A"
                    )
                }.filter { record ->
                    when (recordType) {
                        "A" -> record["type"] == "A"
                        "AAAA" -> record["type"] == "AAAA"
                        else -> true
                    }
                }

                result.success(mapOf(
                    "success" to records.isNotEmpty(),
                    "domain" to domain,
                    "recordType" to recordType,
                    "records" to records,
                    "resolver" to "System"
                ))
            } catch (e: Exception) {
                result.success(mapOf(
                    "success" to false,
                    "domain" to domain,
                    "error" to "DNS lookup failed: ${e.message}"
                ))
            }
        }
    }

    private fun handleReverseDns(call: MethodCall, result: MethodChannel.Result) {
        val ip = call.argument<String>("ip") ?: run {
            result.error("INVALID_ARGS", "Missing IP", null)
            return
        }

        executor.execute {
            try {
                val address = InetAddress.getByName(ip)
                val hostname = address.canonicalHostName

                if (hostname != null && hostname != ip) {
                    result.success(mapOf(
                        "success" to true,
                        "ip" to ip,
                        "ptr" to hostname
                    ))
                } else {
                    result.success(mapOf(
                        "success" to false,
                        "ip" to ip,
                        "error" to "No PTR record found"
                    ))
                }
            } catch (e: Exception) {
                result.success(mapOf(
                    "success" to false,
                    "ip" to ip,
                    "error" to "Reverse DNS failed: ${e.message}"
                ))
            }
        }
    }

    private fun handlePortCheck(call: MethodCall, result: MethodChannel.Result) {
        val host = call.argument<String>("host") ?: run {
            result.error("INVALID_ARGS", "Missing host", null)
            return
        }
        val port = call.argument<Int>("port") ?: run {
            result.error("INVALID_ARGS", "Missing port", null)
            return
        }
        val timeout = call.argument<Int>("timeout") ?: 3

        executor.execute {
            val start = System.currentTimeMillis()
            try {
                val socket = Socket()
                socket.connect(InetSocketAddress(host, port), timeout * 1000)
                val elapsed = System.currentTimeMillis() - start
                socket.close()

                result.success(mapOf(
                    "success" to true,
                    "host" to host,
                    "port" to port,
                    "open" to true,
                    "latency" to "${elapsed}ms",
                    "durationMs" to elapsed.toInt()
                ))
            } catch (e: Exception) {
                val elapsed = System.currentTimeMillis() - start
                result.success(mapOf(
                    "success" to true,
                    "host" to host,
                    "port" to port,
                    "open" to false,
                    "status" to if (e.message?.contains("timed out") == true) "timeout" else "closed",
                    "durationMs" to elapsed.toInt()
                ))
            }
        }
    }

    private fun handleTlsCheck(call: MethodCall, result: MethodChannel.Result) {
        val domain = call.argument<String>("domain") ?: run {
            result.error("INVALID_ARGS", "Missing domain", null)
            return
        }

        executor.execute {
            try {
                val factory = SSLSocketFactory.getDefault() as SSLSocketFactory
                val socket = factory.createSocket(domain, 443) as SSLSocket
                socket.startHandshake()

                val certs = socket.session.peerCertificates
                socket.close()

                if (certs.isNotEmpty() && certs[0] is X509Certificate) {
                    val cert = certs[0] as X509Certificate
                    val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
                    val now = System.currentTimeMillis()
                    val daysRemaining = ((cert.notAfter.time - now) / 86_400_000).toInt()

                    val sans = try {
                        cert.subjectAlternativeNames?.map { it[1].toString() } ?: emptyList()
                    } catch (e: Exception) {
                        emptyList<String>()
                    }

                    result.success(mapOf(
                        "success" to true,
                        "domain" to domain,
                        "issuer" to cert.issuerDN.name,
                        "subject" to cert.subjectDN.name,
                        "validFrom" to dateFormat.format(cert.notBefore),
                        "validUntil" to dateFormat.format(cert.notAfter),
                        "daysRemaining" to daysRemaining,
                        "isExpired" to (daysRemaining < 0),
                        "isExpiringSoon" to (daysRemaining in 0..29),
                        "sans" to sans
                    ))
                } else {
                    result.success(mapOf(
                        "success" to false,
                        "domain" to domain,
                        "error" to "No certificate found"
                    ))
                }
            } catch (e: Exception) {
                result.success(mapOf(
                    "success" to false,
                    "domain" to domain,
                    "error" to "TLS check failed: ${e.message}"
                ))
            }
        }
    }

    private fun handleHttpHeaders(call: MethodCall, result: MethodChannel.Result) {
        val urlString = call.argument<String>("url") ?: run {
            result.error("INVALID_ARGS", "Missing URL", null)
            return
        }

        executor.execute {
            val start = System.currentTimeMillis()
            try {
                val url = URL(urlString)
                val connection = url.openConnection() as java.net.HttpURLConnection
                connection.requestMethod = "HEAD"
                connection.connectTimeout = 10_000
                connection.readTimeout = 10_000
                connection.instanceFollowRedirects = false

                val statusCode = connection.responseCode
                val elapsed = System.currentTimeMillis() - start

                val headers = mutableMapOf<String, String>()
                for (i in 0 until connection.headerFields.size) {
                    val key = connection.getHeaderFieldKey(i)
                    val value = connection.getHeaderField(i)
                    if (key != null) {
                        headers[key] = value
                    }
                }

                connection.disconnect()

                result.success(mapOf(
                    "success" to true,
                    "url" to urlString,
                    "statusCode" to statusCode,
                    "headers" to headers,
                    "durationMs" to elapsed.toInt()
                ))
            } catch (e: Exception) {
                val elapsed = System.currentTimeMillis() - start
                result.success(mapOf(
                    "success" to false,
                    "url" to urlString,
                    "error" to "HTTP headers check failed: ${e.message}",
                    "durationMs" to elapsed.toInt()
                ))
            }
        }
    }

    private fun handleGetPublicIp(result: MethodChannel.Result) {
        executor.execute {
            try {
                val url = URL("https://api.ipify.org?format=json")
                val connection = url.openConnection() as java.net.HttpURLConnection
                connection.connectTimeout = 10_000
                connection.readTimeout = 10_000

                val reader = BufferedReader(InputStreamReader(connection.inputStream))
                val response = reader.readText()
                reader.close()
                connection.disconnect()

                val ipMatch = Regex("\"ip\":\\s*\"([^\"]+)\"").find(response)
                result.success(ipMatch?.groupValues?.get(1))
            } catch (e: Exception) {
                result.success(null)
            }
        }
    }
}
