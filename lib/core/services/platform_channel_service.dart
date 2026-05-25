import 'package:flutter/services.dart';

class PlatformChannelService {
  static const MethodChannel _channel = MethodChannel('com.pocketnoc/network');

  static Future<Map<String, dynamic>> ping(String host, int count) async {
    try {
      final result = await _channel.invokeMethod('ping', {
        'host': host,
        'count': count,
      });
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Platform error',
      };
    }
  }

  static Future<Map<String, dynamic>> traceroute(
      String host, int maxHops) async {
    try {
      final result = await _channel.invokeMethod('traceroute', {
        'host': host,
        'maxHops': maxHops,
      });
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Platform error',
      };
    }
  }

  static Future<Map<String, dynamic>> dnsLookup(
      String domain, String recordType) async {
    try {
      final result = await _channel.invokeMethod('dnsLookup', {
        'domain': domain,
        'recordType': recordType,
      });
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Platform error',
      };
    }
  }

  static Future<Map<String, dynamic>> reverseDns(String ip) async {
    try {
      final result = await _channel.invokeMethod('reverseDns', {
        'ip': ip,
      });
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Platform error',
      };
    }
  }

  static Future<Map<String, dynamic>> portCheck(
      String host, int port, int timeoutSeconds) async {
    try {
      final result = await _channel.invokeMethod('portCheck', {
        'host': host,
        'port': port,
        'timeout': timeoutSeconds,
      });
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Platform error',
      };
    }
  }

  static Future<Map<String, dynamic>> tlsCheck(String domain) async {
    try {
      final result = await _channel.invokeMethod('tlsCheck', {
        'domain': domain,
      });
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Platform error',
      };
    }
  }

  static Future<Map<String, dynamic>> httpHeaders(String url) async {
    try {
      final result = await _channel.invokeMethod('httpHeaders', {
        'url': url,
      });
      return Map<String, dynamic>.from(result as Map);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Platform error',
      };
    }
  }

  static Future<String?> getPublicIp() async {
    try {
      final result = await _channel.invokeMethod('getPublicIp');
      return result as String?;
    } on PlatformException {
      return null;
    }
  }
}
