import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_noc/core/models/diagnostic_result.dart';

void main() {
  group('DiagnosticResult', () {
    test('serializes to JSON correctly', () {
      final result = DiagnosticResult(
        id: 'test-id',
        type: 'ping',
        target: '8.8.8.8',
        data: {'avg': '10.5', 'packetLoss': '0.0'},
        success: true,
        durationMs: 150,
      );

      final json = result.toJson();
      expect(json['id'], 'test-id');
      expect(json['type'], 'ping');
      expect(json['target'], '8.8.8.8');
      expect(json['success'], true);
      expect(json['durationMs'], 150);
      expect(json['data']['avg'], '10.5');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'type': 'dns',
        'target': 'example.com',
        'data': {
          'records': [
            {'type': 'A', 'value': '93.184.216.34'}
          ]
        },
        'success': true,
        'error': null,
        'timestamp': '2025-01-01T00:00:00.000',
        'durationMs': 50,
      };

      final result = DiagnosticResult.fromJson(json);
      expect(result.id, 'test-id');
      expect(result.type, 'dns');
      expect(result.target, 'example.com');
      expect(result.success, true);
      expect(result.durationMs, 50);
    });

    test('generates correct summary for ping', () {
      final result = DiagnosticResult(
        id: 'test',
        type: 'ping',
        target: '8.8.8.8',
        data: {'avg': '15.3', 'packetLoss': '0.0'},
        success: true,
      );
      expect(result.summary, contains('15.3'));
    });

    test('generates correct summary for failed result', () {
      final result = DiagnosticResult(
        id: 'test',
        type: 'ping',
        target: '8.8.8.8',
        data: {},
        success: false,
        error: 'Timeout',
      );
      expect(result.summary, contains('Timeout'));
    });

    test('generates correct summary for port check', () {
      final openPort = DiagnosticResult(
        id: 'test',
        type: 'port',
        target: '8.8.8.8:443',
        data: {'open': true},
        success: true,
        durationMs: 25,
      );
      expect(openPort.summary, contains('open'));

      final closedPort = DiagnosticResult(
        id: 'test',
        type: 'port',
        target: '8.8.8.8:12345',
        data: {'open': false},
        success: true,
      );
      expect(closedPort.summary, contains('closed'));
    });

    test('generates correct summary for TLS', () {
      final result = DiagnosticResult(
        id: 'test',
        type: 'tls',
        target: 'example.com',
        data: {'daysRemaining': 90},
        success: true,
      );
      expect(result.summary, contains('90'));
    });

    test('generates correct summary for DNS', () {
      final result = DiagnosticResult(
        id: 'test',
        type: 'dns',
        target: 'example.com',
        data: {
          'records': [
            {'type': 'A', 'value': '1.2.3.4'}
          ]
        },
        success: true,
      );
      expect(result.summary, contains('1 records'));
    });

    test('handles round-trip serialization', () {
      final original = DiagnosticResult(
        id: 'roundtrip',
        type: 'http',
        target: 'https://example.com',
        data: {'statusCode': 200, 'headers': {'server': 'nginx'}},
        success: true,
        durationMs: 100,
      );

      final json = original.toJson();
      final restored = DiagnosticResult.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.target, original.target);
      expect(restored.success, original.success);
      expect(restored.durationMs, original.durationMs);
    });
  });
}
