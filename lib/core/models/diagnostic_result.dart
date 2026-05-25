import 'package:hive/hive.dart';

part 'diagnostic_result.g.dart';

@HiveType(typeId: 1)
class DiagnosticResult extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final String target;

  @HiveField(3)
  final Map<String, dynamic> data;

  @HiveField(4)
  final bool success;

  @HiveField(5)
  final String? error;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final int durationMs;

  DiagnosticResult({
    required this.id,
    required this.type,
    required this.target,
    required this.data,
    required this.success,
    this.error,
    DateTime? timestamp,
    this.durationMs = 0,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'target': target,
        'data': data,
        'success': success,
        'error': error,
        'timestamp': timestamp.toIso8601String(),
        'durationMs': durationMs,
      };

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) =>
      DiagnosticResult(
        id: json['id'] as String,
        type: json['type'] as String,
        target: json['target'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        success: json['success'] as bool,
        error: json['error'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        durationMs: json['durationMs'] as int? ?? 0,
      );

  String get summary {
    switch (type) {
      case 'ping':
        if (!success) return 'Failed: ${error ?? "Unknown error"}';
        final avg = data['avg'] ?? 'N/A';
        final loss = data['packetLoss'] ?? 'N/A';
        return 'Avg: ${avg}ms | Loss: $loss%';
      case 'dns':
        if (!success) return 'Failed: ${error ?? "Unknown error"}';
        final records = data['records'] as List?;
        return '${records?.length ?? 0} records found';
      case 'port':
        if (!success) return 'Failed: ${error ?? "Unknown error"}';
        final open = data['open'] as bool? ?? false;
        return open ? 'Port open (${durationMs}ms)' : 'Port closed';
      case 'tls':
        if (!success) return 'Failed: ${error ?? "Unknown error"}';
        final daysRemaining = data['daysRemaining'] ?? 'N/A';
        return 'Valid | $daysRemaining days remaining';
      case 'http':
        if (!success) return 'Failed: ${error ?? "Unknown error"}';
        final status = data['statusCode'] ?? 'N/A';
        return 'Status: $status';
      case 'traceroute':
        if (!success) return 'Failed: ${error ?? "Unknown error"}';
        final hops = data['hops'] as List?;
        return '${hops?.length ?? 0} hops';
      case 'reverseDns':
        if (!success) return 'Failed: ${error ?? "Unknown error"}';
        final ptr = data['ptr'] ?? 'N/A';
        return 'PTR: $ptr';
      case 'subnet':
        final hosts = data['usableHosts'] ?? 'N/A';
        return '$hosts usable hosts';
      default:
        return success ? 'Success' : 'Failed';
    }
  }
}
