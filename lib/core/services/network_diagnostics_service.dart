import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pocket_noc/core/services/platform_channel_service.dart';

class NetworkDiagnosticsService {
  static final NetworkDiagnosticsService _instance =
      NetworkDiagnosticsService._internal();
  factory NetworkDiagnosticsService() => _instance;
  NetworkDiagnosticsService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<String?> getPublicIp() async {
    try {
      final nativeIp = await PlatformChannelService.getPublicIp();
      if (nativeIp != null) return nativeIp;
    } catch (_) {}

    try {
      final response = await _dio.get('https://api.ipify.org?format=json');
      return (response.data as Map<String, dynamic>)['ip'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> ping(String host, {int count = 5}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await PlatformChannelService.ping(host, count);
      stopwatch.stop();
      if (result['success'] == true) {
        return {
          ...result,
          'durationMs': stopwatch.elapsedMilliseconds,
        };
      }
      return await _dartPing(host, count, stopwatch);
    } catch (_) {
      return await _dartPing(host, count, stopwatch);
    }
  }

  Future<Map<String, dynamic>> _dartPing(
      String host, int count, Stopwatch stopwatch) async {
    final latencies = <double>[];
    int sent = 0;
    int received = 0;

    for (int i = 0; i < count; i++) {
      sent++;
      try {
        final sw = Stopwatch()..start();
        final addresses = await InternetAddress.lookup(host);
        sw.stop();
        if (addresses.isNotEmpty) {
          received++;
          latencies.add(sw.elapsedMicroseconds / 1000.0);
        }
      } catch (_) {
        // packet lost
      }
    }

    stopwatch.stop();

    if (latencies.isEmpty) {
      return {
        'success': false,
        'error': 'All packets lost',
        'sent': sent,
        'received': 0,
        'packetLoss': 100.0,
        'durationMs': stopwatch.elapsedMilliseconds,
      };
    }

    latencies.sort();
    final avg = latencies.reduce((a, b) => a + b) / latencies.length;
    final packetLoss = ((sent - received) / sent * 100).toDouble();

    return {
      'success': true,
      'sent': sent,
      'received': received,
      'min': latencies.first.toStringAsFixed(2),
      'max': latencies.last.toStringAsFixed(2),
      'avg': avg.toStringAsFixed(2),
      'packetLoss': packetLoss.toStringAsFixed(1),
      'latencies': latencies.map((l) => l.toStringAsFixed(2)).toList(),
      'durationMs': stopwatch.elapsedMilliseconds,
    };
  }

  Future<Map<String, dynamic>> traceroute(String host,
      {int maxHops = 30}) async {
    try {
      final result = await PlatformChannelService.traceroute(host, maxHops);
      if (result['success'] == true) return result;
    } catch (_) {}

    final hops = <Map<String, dynamic>>[];
    for (int ttl = 1; ttl <= maxHops; ttl++) {
      try {
        final sw = Stopwatch()..start();
        final addresses = await InternetAddress.lookup(host);
        sw.stop();
        hops.add({
          'hop': ttl,
          'ip': addresses.isNotEmpty ? addresses.first.address : '*',
          'latency': '${(sw.elapsedMicroseconds / 1000.0).toStringAsFixed(2)}ms',
          'hostname': addresses.isNotEmpty ? addresses.first.host : '*',
        });
        if (addresses.isNotEmpty) break;
      } catch (_) {
        hops.add({
          'hop': ttl,
          'ip': '*',
          'latency': '*',
          'hostname': '*',
        });
      }
    }

    return {
      'success': true,
      'hops': hops,
      'target': host,
    };
  }

  Future<Map<String, dynamic>> dnsLookup(String domain,
      {String recordType = 'A'}) async {
    try {
      final result =
          await PlatformChannelService.dnsLookup(domain, recordType);
      if (result['success'] == true) return result;
    } catch (_) {}

    try {
      final addresses = await InternetAddress.lookup(domain);
      final records = addresses.map((a) => {
            'type': a.type == InternetAddressType.IPv4 ? 'A' : 'AAAA',
            'value': a.address,
            'ttl': 'N/A',
          }).toList();

      return {
        'success': true,
        'domain': domain,
        'recordType': recordType,
        'records': records,
        'resolver': 'System',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'DNS lookup failed: $e',
        'domain': domain,
      };
    }
  }

  Future<Map<String, dynamic>> reverseDns(String ip) async {
    try {
      final result = await PlatformChannelService.reverseDns(ip);
      if (result['success'] == true) return result;
    } catch (_) {}

    try {
      final addr = InternetAddress(ip);
      final result = await addr.reverse();
      return {
        'success': true,
        'ip': ip,
        'ptr': result.host,
      };
    } catch (e) {
      return {
        'success': false,
        'ip': ip,
        'error': 'Reverse DNS failed: $e',
      };
    }
  }

  Future<Map<String, dynamic>> portCheck(String host, int port,
      {int timeoutSeconds = 3}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final nativeResult =
          await PlatformChannelService.portCheck(host, port, timeoutSeconds);
      if (nativeResult['success'] == true) {
        stopwatch.stop();
        return {
          ...nativeResult,
          'durationMs': stopwatch.elapsedMilliseconds,
        };
      }
    } catch (_) {}

    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: Duration(seconds: timeoutSeconds),
      );
      stopwatch.stop();
      socket.destroy();
      return {
        'success': true,
        'host': host,
        'port': port,
        'open': true,
        'latency': '${stopwatch.elapsedMilliseconds}ms',
        'durationMs': stopwatch.elapsedMilliseconds,
      };
    } on SocketException {
      stopwatch.stop();
      return {
        'success': true,
        'host': host,
        'port': port,
        'open': false,
        'status': 'closed',
        'durationMs': stopwatch.elapsedMilliseconds,
      };
    } on TimeoutException {
      stopwatch.stop();
      return {
        'success': true,
        'host': host,
        'port': port,
        'open': false,
        'status': 'timeout',
        'durationMs': stopwatch.elapsedMilliseconds,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'host': host,
        'port': port,
        'error': 'Port check failed: $e',
        'durationMs': stopwatch.elapsedMilliseconds,
      };
    }
  }

  Future<Map<String, dynamic>> httpHeaders(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    try {
      final nativeResult = await PlatformChannelService.httpHeaders(url);
      if (nativeResult['success'] == true) return nativeResult;
    } catch (_) {}

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.head(
        url,
        options: Options(
          followRedirects: false,
          validateStatus: (status) => true,
        ),
      );
      stopwatch.stop();

      final headers = <String, String>{};
      response.headers.forEach((name, values) {
        headers[name] = values.join(', ');
      });

      return {
        'success': true,
        'url': url,
        'statusCode': response.statusCode,
        'headers': headers,
        'durationMs': stopwatch.elapsedMilliseconds,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'url': url,
        'error': 'HTTP headers check failed: $e',
        'durationMs': stopwatch.elapsedMilliseconds,
      };
    }
  }

  Future<Map<String, dynamic>> tlsCheck(String domain) async {
    try {
      final nativeResult = await PlatformChannelService.tlsCheck(domain);
      if (nativeResult['success'] == true) return nativeResult;
    } catch (_) {}

    try {
      final socket = await SecureSocket.connect(
        domain,
        443,
        timeout: const Duration(seconds: 10),
      );

      final cert = socket.peerCertificate;
      socket.destroy();

      if (cert == null) {
        return {
          'success': false,
          'domain': domain,
          'error': 'No certificate found',
        };
      }

      final now = DateTime.now();
      final daysRemaining = cert.endValidity.difference(now).inDays;

      return {
        'success': true,
        'domain': domain,
        'issuer': cert.issuer.toString(),
        'subject': cert.subject.toString(),
        'validFrom': cert.startValidity.toIso8601String(),
        'validUntil': cert.endValidity.toIso8601String(),
        'daysRemaining': daysRemaining,
        'isExpired': daysRemaining < 0,
        'isExpiringSoon': daysRemaining < 30,
        'sha1': cert.sha1.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'domain': domain,
        'error': 'TLS check failed: $e',
      };
    }
  }

  String getNetworkType() {
    return 'Unknown';
  }
}
